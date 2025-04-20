function Get-PdxBuildExtension {
	<#
	.SYNOPSIS
		Lists registered paradox modding build extensions.
	
	.DESCRIPTION
		Lists registered paradox modding build extensions.
		These are used to help simplify mod build scripts and usually provided by game-specific modules.
	
	.PARAMETER Name
		Name of the extension to look for.
		Defaults to *
	
	.PARAMETER Tags
		Tags to search for.
		Any extension with at least one match is returned.
	
	.EXAMPLE
		PS C:\> Get-PdxBuildExtension

		Lists all registered paradox modding build extensions.
	#>
	[CmdletBinding()]
	param (
		[PsfArgumentCompleter('Paradox.Modding.BuildExtension.Name')]
		[string]
		$Name = '*',

		[PsfArgumentCompleter('Paradox.Modding.BuildExtension.Tags')]
		[string[]]
		$Tags
	)
	process {
		$script:buildExtensions.Values | Where-Object {
			$_.Name -like $Name -and
			(
				-not $Tags -or
				(@($_.Tags).Where{ $_ -in $Tags })
			)
		}
	}
}