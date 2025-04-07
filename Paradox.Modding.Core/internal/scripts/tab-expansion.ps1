Register-PSFTeppScriptblock -Name 'Paradox.Modding.ChildFolder' -ScriptBlock {
	$root = '.'
	if ($fakeBoundParameter.Path) {
		$root = $fakeBoundParameter.Path
	}

	Get-ChildItem -Path $root -Directory | ForEach-Object {
		@{ Text = $_.Name; Tooltip = $_.FullName}
	}
} -Global

Register-PSFTeppScriptblock -Name 'Paradox.Modding.BuildExtension.Tags' -ScriptBlock {
	(Get-PdxBuildExtension).Tag | Write-Output | Sort-Object -Unique
} -Global

Register-PSFTeppScriptblock -Name 'Paradox.Modding.BuildExtension.Name' -ScriptBlock {
	(Get-PdxBuildExtension).Name | Sort-Object -Unique
} -Global