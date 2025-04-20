function ConvertTo-ParadoxArray {
	<#
	.SYNOPSIS
		Converts an array into the paradox-config equivalent.
	
	.DESCRIPTION
		Converts an array into the paradox-config equivalent.
	
	.PARAMETER Data
		The entries in the array to convert
	
	.PARAMETER Indentation
		What indentation level to maintain within the rows.
	
	.EXAMPLE
		PS C:\> ConvertTo-ParadoxArray -Data $entries -Indentation 5
	
		Converts the provided array into the paradox-config equivalent with 5 tabs as indentation (6 for the individual entries).
	#>
	[OutputType([string])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[object[]]
		$Data,

		[int]
		$Indentation
	)
	process {
		$results = do {
			'{'
			foreach ($line in $Data) { "$("`t" * ($Indentation + 1))$line"}
			"$("`t" * $Indentation)}"
		}
		while ($false)
		$results -join "`n"
	}
}