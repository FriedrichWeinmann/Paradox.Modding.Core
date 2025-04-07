function New-PdxLocalizedString {
	<#
	.SYNOPSIS
		Creates a new set of localization data for a Paradox game mod.
	
	.DESCRIPTION
		Creates a new set of localization data for a Paradox game mod.
		This can be used to conveniently build up localization data as you generate mod content,
		and later export it as localization files.

		Mostly used to enable mods to keep content and localization together.
		Especially when you are not planning to localize anyway.

		Add entries with Add-PdxLocalizedString
		Export to disk with Export-PdxLocalizedString
	
	.EXAMPLE
		PS C:\> New-PdxLocalizedString
		
		Generates a hashtable, mapping all the supported languages.
		There really is nothing else to it.
	#>
	[OutputType([hashtable])]
	[CmdletBinding()]
	param ()
	process {
		@{
			braz_por = @{ }
			english = @{ }
			french = @{ }
			german = @{ }
			japanese = @{ }
			polish = @{ }
			russian = @{ }
			simp_chinese = @{ }
			spanish = @{ }
		}
	}
}