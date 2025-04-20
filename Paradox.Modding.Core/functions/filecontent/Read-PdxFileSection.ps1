function Read-PdxFileSection {
	<#
	.SYNOPSIS
		Read a paradox game file and break it into individual entries.
	
	.DESCRIPTION
		Read a paradox game file and break it into individual entries.
		Use this to parse out individual entries in a file containing many elements.
		E.g.: Use this to get a list of all techs from all the files in the "common/technologies" folder (including the individual definitions).
	
	.PARAMETER Path
		Path to the files to parse.

	.PARAMETER IncludeComments
		Also include comments _within_ an individual entry.
		by default, commented out lines are not included.
		Comments at the root level will always be ignored.
	
	.EXAMPLE
		PS C:\> Get-ChildItem -Path .\common\technologies | Read-PdxFileSection
		
		Read all technologies from all tech files.
	#>
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias('FullName')]
		[PSFFileLax]
		$Path,

		[switch]
		$IncludeComments
	)

	process {
		foreach ($badFile in $Path.FailedInput) {
			Write-PSFMessage -Level Warning -Message "Bad input - either does not exist or not a file: {0}" -StringValues $badFile
		}

		foreach ($file in $Path) {
			$lines = Get-Content -LiteralPath $file | Where-Object {
				$IncludeComments -or
				$_ -notmatch '^\s{0,}#'
			}

			$currentLines = @()
			foreach ($line in $lines) {
				# Skip empty lines outside of a section
				if (-not $line.Trim() -and -not $currentLines) { continue }

				# Skip leading declarations
				if (-not $currentLines -and $line -notmatch '=\s{0,}\{' -and $line -notmatch '^#') { continue }

				$currentLines += $line

				# Move to next line if not last line
				if ($line -notmatch '^}') { continue }

				[PSCustomObject]@{
					File         = $file
					Name         = $currentLines[0] -replace '.{0,}?(\w+)\s{0,}=.{0,}', '$1'
					Lines        = $currentLines
					LinesCompact = $currentLines | Get-SubString -Trim "`t "
					Text         = $currentLines -join "`n"
				}
				$currentLines = @()
			}
		}
	}
}