function Export-PdxLocalizedString {
	<#
	.SYNOPSIS
		Creates language files from a localized strings hashtable.
	
	.DESCRIPTION
		Creates language files from a localized strings hashtable.
		Expects a hashtable with one nested hashtable per language, using the system language name as key.

		Create a new strings hashtable with New-PdxLocalizedString
		Add entries with Add-PdxLocalizedString
	
	.PARAMETER Strings
		A hashtable with one nested hashtable per language, using the system language name as key.
	
	.PARAMETER ModRoot
		The root path, where the mod begins.
	
	.PARAMETER Name
		The basic name of the strings file to be created.

	.PARAMETER ToLower
		Whether localization keys should be converted to lowercase
	
	.EXAMPLE
		PS C:\> Export-PdxLocalizedString -Strings $strings -ModRoot $resolvedPath -Name $Definition.Name
		
		Exports the localization stored in $strings to the correct place under the mod root, with the name provided.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[hashtable]
		$Strings,

		[Parameter(Mandatory = $true)]
		[string]
		$ModRoot,
		
		[Parameter(Mandatory = $true)]
		[string]
		$Name,

		[switch]
		$ToLower
	)
	process {
		foreach ($language in $Strings.Keys) {
			$lines = @()
			foreach ($pair in $strings[$language].GetEnumerator()) {
				if ($ToLower) { $lines += ' {0}:0 "{1}"' -f $pair.Key.ToLower(), ($pair.Value -replace '"',"'") }
				else { $lines += ' {0}:0 "{1}"' -f $pair.Key, ($pair.Value -replace '"',"'") }
			}
			$lines = @("l_$($language):") + ($lines | Sort-Object)

			$localizedText = $lines -join "`n"
			$encoding = [System.Text.UTF8Encoding]::new($true)
			$outFolder = Join-Path -Path $ModRoot -ChildPath "localisation/$language"
			if (-not (Test-Path -Path $outFolder)) { $null = New-Item -Path $outFolder -ItemType Directory -Force }
			$outPath = Join-Path -Path $ModRoot -ChildPath "localisation/$language/$($Name)_l_$($language).yml"
			[System.IO.File]::WriteAllText($outPath, $localizedText, $encoding)
		}
	}
}