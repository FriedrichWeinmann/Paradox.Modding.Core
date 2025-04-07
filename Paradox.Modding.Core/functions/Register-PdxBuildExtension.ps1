function Register-PdxBuildExtension {
	<#
	.SYNOPSIS
		Register a new build logic specific to a given paradox game.
	
	.DESCRIPTION
		Register a new build logic specific to a given paradox game.
		These can be applied / selected when building mods to simplify/replace build scripts in mods.
	
	.PARAMETER Name
		Name of the build extension.
	
	.PARAMETER Description
		Description of what the build extension does.
	
	.PARAMETER Tags
		Tags to apply to the extension.
		Extensions are usually selected by tag.
		Each extension should at least include a tag for the game it applies to.
	
	.PARAMETER Code
		The code implementing the build logic.
		It will receive a single value as input: A hashtable with multiple entrie.
		As a least minimum, this will include:
		- Root: The Path to the mod being built
		- Name: The name of the mod
		- Author: The author of the mod
		- Version: The version of the mod
		Other than "Root" or "Name", data is taken from a "config.psd" file in the root mod folder if present.
		Individual games may define (and use) additional config settings as desired.
	
	.EXAMPLE
		PS C:\> Register-PdxBuildExtension -Name 'Stellaris.Edict' -Description 'Builds Stellaris edicts written as psd1 files' -Tags stellaris, edicts -Code $edictExt

		Registers a new build extension to simplify building Stellaris edicts.
	#>
	[CmdletBinding()]
	param (
		[PsfValidateScript('PSFramework.Validate.SafeName')]
		[string]
		$Name,

		[string]
		$Description,

		[string[]]
		$Tags,

		[scriptblock]
		$Code
	)
	process {
		$script:buildExtensions[$Name] = [PSCustomObject]@{
			PSTypeName  = 'Paradox.Modding.Core.BuildExtension'
			Name        = $Name
			Description = $Description
			Tags        = $Tags
			Code        = $Code
		}
	}
}