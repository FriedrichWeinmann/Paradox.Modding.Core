function New-PdxConfigEntry {
	<#
	.SYNOPSIS
		Create a configuration entry, later to be written to disk as a Paradox mod file.
	
	.DESCRIPTION
		Create a configuration entry, later to be written to disk as a Paradox mod file.
		This command should rarely be used directly and is meant for the other modules in the kit as a helper utility.

		It is part of the process converting a psd1-based configuration file into actual mod files.
		The results of this command are later processed by ...
		- "Export-PdxLocalizedString" for localization data
		- "ConvertTo-PdxConfigFormat" for export as a Paradox-compliant mod file

		Parameter Note: IDictionary
		Most parameters accept a System.Collections.IDictionary as input.
		In the context of PowerShell, this usually means one of two options:
		- A Hashtable: $output = @{}
		- An Ordered Dictionary: $output = [ordered]@{}
		The latter has the advantage of maintaining the correct order of properties and is recommended for modding with this tool.

		For an example implementation / usage, see here:
		https://github.com/FriedrichWeinmann/Paradox.Modding.Stellaris/blob/master/Paradox.Modding.Stellaris/functions/ConvertTo-PdsBuilding.ps1
	
	.PARAMETER Entry
		The individual configuration entry with the properties that make up the actual dataset.
		Whether that is a building definition, a new army type, and edict or whatever else.
	
	.PARAMETER Name
		The name of the entry.
		Used for localization keys.
	
	.PARAMETER Defaults
		Default settings that apply, if there is nothing specified in the Entry for it.
	
	.PARAMETER Output
		The result object.
		All processing is applied to this item.
		Specifying it allows you to pre-process it, adding the first entries yourself, before passing it to this command, which will affect the order of entries on the exported result.
		Defaults to: An empty ordered dictionary.
	
	.PARAMETER Common
		Common properties and their aliases.
		Entries specified here will be first - and in the order of its entries - in the exported mod data.
		It allows you to ensure a fairly consistent order for commonly needed properties.
		It also allows you to add aliases to some of the more common properties.
		Example:
		@{
			CanBuild = 'can_build'
			Potential = 'potential'
		}
		The first entry allows you to either specify "CanBuild" or "can_build" in the config file - they'll mean the same thing.
		The second entry ensures the casing of "Potential" in the exported mod file will always be "potential", no matter how it is specified in the config file.
		It will also ensure, that in all exported entries, "can_build" comes before "potential" and all other entries will be below them.
	
	.PARAMETER Strings
		The localization data that will later be exported.
		Use "New-PdxLocalizedString" to generate this item.
		This allows you to collect localized strings from multiple entries and only generate one localization file at the end of the process.
		For example, this allows your config file with ten buildings defined to only generate one set of localization files, containing all the strings of the ten buildings bundled together.
	
	.PARAMETER LocalizationProperties
		Which properties on the Entry correspond to localization entries and not mod dataset information.
		They will NOT become part of the mod data, and instead become part of the localization.
		Example:
		@{
			Name = 'edict_{0}'
			Description = 'edict_{0}_desc'
		}
		This would mean that for each entry, the configuration entries "Name" and "Description" will not become part of the mod, and instead become localization.
		If now our entire configuration entry be this:
		infernal_diplomacy              = @{
			Name        = "Infernal Diplomacy"
			Description = "Who wouldn't want to be your friend?"
			Modifier    = @{
				envoys_add             = 1
			}
		}
		Then this tool will generate two strings:
		infernal_diplomacy:0 "Infernal Diplomacy"
		infernal_diplomacy_desc:0 "Who wouldn't want to be your friend?"
	
	.PARAMETER TypeMap
		Given the way PowerShell works, sometimes types are not exactly straightforward.
		With this parameter we can define a specific data type for a setting on an entry.
		Example:
		@{
			upgrades = 'array'
			prerequisites = 'array'
		}
		If our configuration entry now specifies this:
		prerequisites = 'tech_basic_science_lab_2'
		Which is a plain string, it will then be converted into an array (with a single string) instead:
		prerequisites = @('tech_basic_science_lab_2')
	
	.PARAMETER Ignore
		Properties on Entry that should be ignored.
		Use this for properties you process outside of this command.
		For example, to simplify resource cost processing, which can be simple or incredibly complex, depending on how many conditions you want to apply or what kinds of resources you want to demand.
		Using Stellaris buildings for an example:
		- Most buildings cost Minerals to build (and nothing else).
		- Some buildings require rare resources as well.
		- Some buildings require rare resources, UNLESS a specific requirement is met.
		
		To make this convenient to mod, we want then support different specifications:
		- Provide a simple number, and we assume you mean minerals
		- Provide a simple hashtable, and we assume you provide your own calculation

		However, this command is not equipped to deal with this!
		So, in order to resolve this, you do that determination yourself and have this command skip the property instead.
	
	.EXAMPLE
		PS C:\> New-PdxConfigEntry -Entry $buildingData -Name $buildingName -Defaults $data.Core -Common $commonProps -Output $newBuilding -Strings $strings -LocalizationProperties $localeMap -Ignore Cost, Upkeep -TypeMap $typeMap

		Does wild stuff.
		Essentially, this merges the config entry's settings with the default settings, ensures strings are properly added to the list of strings to export, types are properly enforced and Cost and Upkeep properties are skipped.
	
	.LINK
		https://github.com/FriedrichWeinmann/Paradox.Modding.Stellaris/blob/master/Paradox.Modding.Stellaris/functions/ConvertTo-PdsBuilding.ps1
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[OutputType([System.Collections.IDictionary])]
	[CmdletBinding(DefaultParameterSetName = 'Default')]
	param (
		[Parameter(Mandatory = $true)]
		[System.Collections.IDictionary]
		$Entry,

		[Parameter(Mandatory = $true, ParameterSetName = 'Localized')]
		[string]
		$Name,

		[System.Collections.IDictionary]
		$Defaults = @{},

		[System.Collections.IDictionary]
		$Output = ([ordered]@{ }),

		[System.Collections.IDictionary]
		$Common = @{ },

		[Parameter(Mandatory = $true, ParameterSetName = 'Localized')]
		[hashtable]
		$Strings,

		[Parameter(Mandatory = $true, ParameterSetName = 'Localized')]
		[hashtable]
		$LocalizationProperties,

		[hashtable]
		$TypeMap = @{},

		[string[]]
		$Ignore
	)
	begin {
		$nonCommonDefaults = @{ }
		foreach ($pair in $Defaults.GetEnumerator()) {
			if ($pair.Key -notin $Common.Keys) {
				$nonCommonDefaults[$pair.Key] = $pair.Value
			}
		}

		$propsToIgnore = @($Ignore) + $LocalizationProperties.Keys | Remove-PSFNull
	}
	process {
		#region Localization
		if ($Name) {
			foreach ($localizationEntry in $LocalizationProperties.GetEnumerator()) {
				if ($Entry.$($localizationEntry.Key) -is [string]) { Add-PdxLocalizedString -Key ($localizationEntry.Value -f $Name) -Text $Entry.$($localizationEntry.Key) -Strings $Strings }
				elseif ($Entry.$($localizationEntry.Key).english) { Add-PdxLocalizedString -Key ($localizationEntry.Value -f $Name) -Text $Entry.$($localizationEntry.Key).english -Localized $Entry.$($localizationEntry.Key) -Strings $Strings }
			}
		}
		#endregion Localization

		#region Well-Known Properties
		foreach ($property in $Common.GetEnumerator()) {
			if ($Entry.Keys -contains $property.Key) { $Output[$property.Value] = $Entry[$property.Key] }
			elseif ($Entry.Keys -contains $property.Value) { $Output[$property.Value] = $Entry[$property.Value] }
			elseif ($Defaults.Keys -contains $property.Key) { $Output[$property.Value] = $Defaults[$property.Key] }
			elseif ($Defaults.Keys -contains $property.Value) { $Output[$property.Value] = $Defaults[$property.Value] }
		}
		#endregion Well-Known Properties

		#region Other Nodes
		foreach ($pair in $Entry.GetEnumerator()) {
			if ($pair.Key -in $propsToIgnore) { continue } # Should Ignore
			if ($pair.Key -in $Common.Keys) { continue } # Handled in the last step
			$Output[$pair.Key] = $pair.Value
		}

		foreach ($pair in $nonCommonDefaults.GetEnumerator()) {
			if ($pair.Key -in $propsToIgnore) { continue }
			if ($pair.Key -in $Entry.Keys) { continue }
			$Output[$pair.Key] = $pair.Value
		}
		#endregion Other Nodes

		#region Process Type Conversion/Assurance
		foreach ($typeEntry in $TypeMap.GetEnumerator()) {
			if ($Output.Keys -notcontains $typeEntry.Key) { continue }

			switch ($typeEntry.Value) {
				'array' {
					$Output[$typeEntry.Key] = @($Output[$typeEntry.Key])
				}
				default { Write-PSFMessage -Level Warning -Message 'Unexpected type coercion type for property {0}. Defined type "{1}" is not implemented' -StringValues $typeEntry.Key, $typeEntry.Value -Target $Output }
			}
		}
		#endregion Process Type Conversion/Assurance

		$Output
	}
}