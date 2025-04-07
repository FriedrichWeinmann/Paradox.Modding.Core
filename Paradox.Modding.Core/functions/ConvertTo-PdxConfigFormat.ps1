function ConvertTo-PdxConfigFormat {
	<#
	.SYNOPSIS
		Builds a full Paradox Configuration file text from hashtable.
	
	.DESCRIPTION
		Builds a full Paradox Configuration file text from hashtable.
		The hashtable must have the same format as the file in the Paradox format is supposed to have.

		Tip: Use [ordered] hashtables in order to preserve order of entries.

		Duplicate Keys:
		In the Paradox format, there are often multiple entries with the same name.
		E.g.: Decisions with three options: Each option starts on the saem "option" key.
		Hashtables in c#/PowerShell/.NET do not support duplicate keys!!
		In those situations, you can append an index behind the key, that will automatically be removed during conversion:
		"optionþ1þ" becomes "option"
		"optionþ2þ" becomes "option"
		"optionþ10þ" becomes "option"

		The "þ" character is the "Thorn" symbol from the icelandic language and should never conflict with an actual key value.
		It can be typed by keeping the left ALT key pressed and type "0254" on the numpad.
	
	.PARAMETER Data
		The data assets to convert into the target format.
	
	.PARAMETER Indentation
		What indentation level to start at.
		Will automatically increment for nested settings.
		Uses tabs for indentation.
	
	.PARAMETER TopLevel
		Whether the object provided is a top-levvel object.
		Top-Level Objects will not use opening and closing curly braces.
		They also skip the auto-indentation for direct members.
	
	.EXAMPLE
		PS C:\> $decisions | ConvertTo-PdxConfigFormat
		
		Converts the decisions provided into valid mod strings.
	#>
	[OutputType([string])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[ValidateScript({ $_ -as [hashtable]})]
		[object[]]
		$Data,

		[int]
		$Indentation,

		[switch]
		$TopLevel
	)
	begin {
		$boolMap = @{
			$true = 'yes'
			$false = 'no'
		}

		$effectiveIndentation = $Indentation
		if (-not $TopLevel) { $effectiveIndentation++ }
	}
	process {
		foreach ($entry in $Data) {
			$results = do {
				if (-not $TopLevel) { "{" }

				foreach ($pair in $entry.GetEnumerator()) {
					if ($null -eq $pair.Value) { throw "Error processing $($pair.Key): NULL is not a supported value!" }
					$value = switch ($pair.Value.GetType()) {
						([string]) { $pair.Value }
						([int]) { $pair.Value }
						([double]) { $pair.Value }
						([bool]) { $boolMap[$pair.Value] }
						([hashtable]) { ConvertTo-ParadoxConfig -Data $pair.Value -Indentation ($effectiveIndentation); break }
						([ordered]) { ConvertTo-ParadoxConfig -Data $pair.Value -Indentation ($effectiveIndentation); break }
						default {
							throw "Error processing $($pair.Key): Unexpected type $($pair.Value.GetType().FullName) | $($pair.Value)"
						}
					}
					# Paradox Config can use the same key multiple times, hashtables cannot.
					# To solve this, we can append a "þ<number>þ" suffix in the hashtable which is removed during conversion
					"$("`t" * $effectiveIndentation)$($pair.Key -replace 'þ\d+þ') = $value"
				}

				if (-not $TopLevel) { "$("`t" * $Indentation)}" }
			}
			while ($false)
			$results -join "`n"
		}
	}
}