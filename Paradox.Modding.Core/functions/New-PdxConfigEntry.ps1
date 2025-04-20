function New-PdxConfigEntry {
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[OutputType([System.Collections.Specialized.OrderedDictionary])]
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
		$Output = @{ },

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