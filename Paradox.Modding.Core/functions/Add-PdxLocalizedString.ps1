function Add-PdxLocalizedString {
	<#
	.SYNOPSIS
		Adds a localization entry into a previously created localization hashtable.
	
	.DESCRIPTION
		Adds a localization entry into a previously created localization hashtable.
		This allows defining a default text for languages otherwise not defined (or just simply going mono-lingual).
	
	.PARAMETER Key
		The string key to provide text for.
	
	.PARAMETER Text
		The default text to apply.
	
	.PARAMETER Localized
		Any additional string mappings for different languages.
	
	.PARAMETER Strings
		The central strings dictionary.
		Use New-PdxLocalizedString to generate one.
	
	.EXAMPLE
		PS C:\> Add-PdxLocalizedString -Key $traitLocName -Text 'Suicide Pact' -Localized $trait.Localized -Strings $strings

		Adds the string in $traitLocName with a default text of "Suicide Pact" and whatever we cared to localize to the $strings dictionary
	#>
	[CmdletBinding()]
	param (
		[string]
		$Key,
		
		[AllowEmptyString()]
		[AllowNull()]
		[string]
		$Text,

		[AllowNull()]
		[hashtable]
		$Localized,

		[hashtable]
		$Strings
	)

	if (-not $Strings) { return }
	$languages = $Strings.Keys

	foreach ($language in $languages) {
		$Strings[$language][$Key] = $Text
		if (-not $Localized) { continue }
		if ($Localized[$language]) {
			$Strings[$language][$Key] = $Localized[$language]
		}
	}
}