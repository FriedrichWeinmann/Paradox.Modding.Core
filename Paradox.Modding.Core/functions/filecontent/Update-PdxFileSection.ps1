function Update-PdxFileSection {
	<#
	.SYNOPSIS
		Modifies the content of a section read from a Paradox content file.
	
	.DESCRIPTION
		Modifies the content of a section read from a Paradox content file.
		Use this to modify the sections read through "Read-PdxFileSection".

		IMPORTANT:
		This does _NOT_ modify the files those were read from - you'll have to write back the sections yourself (or put them in new files).
	
	.PARAMETER Section
		The section data to modify.
		Use "Read-PdxFileSection" to generate them.
	
	.PARAMETER Rule
		The rules to apply to each section.
		Currently supported rule-types:
		- Insert: Adds extra content above or below existing lines.
		- Replace: Use regex replacement on the entire section.

		Examples:
		> Insert:
		@{
			Type = "Insert"
			Scope = 'Above'
			Line = 'station_modifier = {'
			Text = '# Will turn the base into a juggernaut'
		}

		Notes:
		The "Text"-Field can have any number of lines of text, as needed.
		
		> Replace:
		@{
			Type = 'Replace'
			Old = 'max = 320 # 20 \* 16'
			New = 'max = 3200 # 200 * 16'
		}

		Notes:
		This replacement uses regular expressions. Mind your special characters.
		It applies the ruleset as used by C#.
	
	.PARAMETER PassThru
		Return the processed section object.
		By default, this command returns nothing, merely modifying the sections passed to it.
	
	.EXAMPLE
		PS C:\> Update-PdxFileSection -Section $allComponents -Rule $prerequisites

		Updates all the sections in $allComponents based on the rules in $prerequisites.
		- See description on "-Rule" parameter to see how rules should be defined.
		- See "Read-PdxFileSection" command for how to obtain sections.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[object[]]
		$Section,

		[hashtable[]]
		$Rule,

		[switch]
		$PassThru
	)

	process {
		foreach ($entry in $Section) {
			:rules foreach ($ruleItem in $Rule) {
				switch ($ruleItem.Type) {
					'Insert' {
						$index = $entry.Lines.IndexOf($ruleItem.Line)
						if ($index -lt 0) { $index = $entry.LinesCompact.IndexOf($ruleItem.Line) }
						if ($index -lt 0) {
							Write-PSFMessage -Level Warning -Message "Error updating {0}: Line not found: {1}" -StringValues $entry.Name, $ruleItem.Line -Target $entry
							continue rules
						}

						$start = $index
						if ('Above' -eq $ruleItem.Scope) { $start = $start - 1 }

						$newLines = $entry.Lines[0..$start] + ($ruleItem.Text -split "[`n`r]+") + $entry.Lines[($start + 1)..($entry.Lines.Count - 1)]
						$entry.Lines = $newLines
						$entry.LinesCompact = $newLines | Get-SubString -Trim "`t "
						$entry.Text = $NewLines -join "`n"
					}
					'Replace' {
						if ($ruleItem.FullText) {
							$newText = $entry.Text -replace $ruleItem.Old, $ruleItem.New
							$newLines = $newText -split '[\n\r]+'
						}
						else {
							$newLines = $entry.Lines -replace $ruleItem.Old, $ruleItem.New
						}
						$entry.Lines = $newLines
						$entry.LinesCompact = $newLines | Get-SubString -Trim "`t "
						$entry.Text = $NewLines -join "`n"
					}
					default {
						Write-PSFMessage -Level Warning -Message 'Error processing rule: Unexpected rule type: {0}' -StringValues $ruleItem.Type -Data @{ Rule = $ruleItem } -Target $entry
					}
				}
			}
			if ($PassThru) { $entry }
		}
	}
}