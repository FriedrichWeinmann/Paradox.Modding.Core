function Build-PdxMod {
	<#
	.SYNOPSIS
		Builds a a paradox game mod.
	
	.DESCRIPTION
		Builds a a paradox game mod.
		It will pick up all folders in the target Path with a matching name and treat them as mods.
		Then it builds & deploys them.

		This includes:

		- Copying the entire folder to a staging path.
		- Executing the build.ps1 script in the root folder (if present)
		- Apply any build extensions
		- Removing all PowerShell files from the mod structure
		- Replacing the mod with any previous versions in the destination path.
	
	.PARAMETER Path
		Directory where mod sources are looked for.
		Defaults to the current folder.
	
	.PARAMETER Name
		Name of the mod to build.
		Defaults to *

	.PARAMETER Tags
		Build extensions to apply based on their tags.
		These are provided by game-specific modules.
		This allows you to automatically apply game-specific build actions, without needing your own build script.
	
	.PARAMETER Game
		The game to build for.
		This is used to automatically pick the output folder for where that game is looking for mods.
	
	.PARAMETER OutPath
		The destination folder where to place the built mod.
		Use this if you do not want to deploy the mods straight to your game.

	.PARAMETER BadExtensions
		File extensions that should not remain in your mod structure.
		Before finalizing and deploying the mod, all files with one of the included extensions will be deleted from the staging copy of your mods.
		Defaults to: .ps1, .psd1

		Note: This will NOT affect the files in your source structure, only in the copy used to wrap up and deploy your mod.

	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.EXAMPLE
		PS C:\> Build-PdxMod -Path C:\code\mods\Stellaris -Game Stellaris

		Picks up all folders under "C:\code\mods\Stellaris" and deploys them as Stellaris mod to where your Stellaris will look for mods.
	#>
	[CmdletBinding(DefaultParameterSetName = 'Game')]
	param (
		[string]
		$Path = '.',

		[PsfArgumentCompleter('Paradox.Modding.ChildFolder')]
		[string]
		$Name = '*',

		[PsfArgumentCompleter('Paradox.Modding.BuildExtension.Tags')]
		[string[]]
		$Tags,

		[Parameter(Mandatory = $true, ParameterSetName = 'Game')]
		[ValidateSet('EU4', 'HOI4', 'Imperator', 'CK2', 'CK3', 'Victoria3', 'Stellaris')]
		[string]
		$Game,

		[Parameter(Mandatory = $true, ParameterSetName = 'Path')]
		[string]
		$OutPath,

		[string[]]
		$BadExtensions = @('.ps1','.psd1'),

		[switch]
		$EnableException
	)

	begin {
		#region Utility Functions
		function Build-ModInstance {
			[CmdletBinding()]
			param (
				[string]
				$Path,

				[string]
				$Name,

				[AllowEmptyCollection()]
				[string[]]
				$Tags,

				[AllowEmptyCollection()]
				[string[]]
				$BadExtensions
			)

			# Prepare Configuration
			$rootPath = Join-Path -Path $Path -ChildPath $Name
			$modCfg = @{
				Author  = 'unspecified'
				Version = 'unspecified'
			}
			$configPath = Join-Path -Path $rootPath -ChildPath 'config.psd1'
			if (Test-Path -Path $configPath) {
				$config = Import-PSFPowerShellDataFile -Path $configPath
				foreach ($entry in $config.GetEnumerator()) {
					$modCfg[$entry.Key] = $entry.Value
				}
			}
			$modCfg.Name = $Name
			$modCfg.Root = $rootPath
			
			# Execute build script if present
			$buildPath = Join-Path -Path $rootPath -ChildPath 'build.ps1'
			if (Test-Path -Path $buildPath) {
				& $buildPath
			}

			# Apply Build Extensions
			if ($Tags) {
				$extensions = Get-PdxBuildExtension -Tags $Tags
				foreach ($extension in $extensions) {
					Write-PSFMessage -Level Verbose -Message '      Applying build Extension: {0}' -StringValues $extension.Name
					& $extension.Code $modCfg
				}
			}

			# Remove all PowerShell-native content from staging folder
			Get-ChildItem -Path $rootPath -Recurse | Where-Object Extension -In $BadExtensions | Remove-Item
		}

		function Deploy-ModInstance {
			[CmdletBinding()]
			param (
				[string]
				$Path,

				[string]
				$Name,

				[string]
				$Destination
			)

			$sourceRoot = Join-Path -Path $Path -ChildPath $Name
			$destinationRoot = Join-Path -Path $Destination -ChildPath $Name

			if (Test-Path -Path $destinationRoot) {
				Remove-Item -Path $destinationRoot -Recurse -Force
			}
			Move-Item -Path $sourceRoot -Destination $Destination -Force
		}
		#endregion Utility Functions

		if ($Game) {
			switch ($Game) {
				'CK3' { $OutPath = "$([System.Environment]::GetFolderPath("MyDocuments"))\Paradox Interactive\Crusader Kings III\mod" }
				'EU4' { $OutPath = "$([System.Environment]::GetFolderPath("MyDocuments"))\Paradox Interactive\Europa Universalis IV\mod" }
				'HOI4' { $OutPath = "$([System.Environment]::GetFolderPath("MyDocuments"))\Paradox Interactive\Hearts of Iron IV\mod" }
				'Imperator' { $OutPath = "$([System.Environment]::GetFolderPath("MyDocuments"))\Paradox Interactive\Imperator\mod" }
				'Stellaris' { $OutPath = "$([System.Environment]::GetFolderPath("MyDocuments"))\Paradox Interactive\Stellaris\mod" }
				default { Stop-PSFFunction -Message "Game $Game not implemented yet! Use '-OutPath' instead to manually pick the deployment path!" -Cmdlet $PSCmdlet -EnableException $true }
			}
		}

		$tempDirectory = New-PSFTempDirectory -ModuleName PDX -Name Staging
	}
	process {
		Write-PSFMessage -Level Host -Message "Building Mods in '$Path' to '$OutPath'"
		foreach ($modRoot in Get-ChildItem -Path $Path -Directory) {
			if ($modRoot.Name -notlike $Name) { continue }
			if ($modRoot.Name -eq '.vscode') { continue }

			try {
				Write-PSFMessage -Level Host -Message "  Processing: {0}" -StringValues $modRoot.Name -Target $modRoot.Name
				Write-PSFMessage -Level Host -Message "    Staging Mod" -Target $modRoot.Name
				Copy-Item -LiteralPath $modRoot.FullName -Destination $tempDirectory -Recurse
				
				Write-PSFMessage -Level Host -Message "    Building Mod. Tags: {0}" -StringValues ($Tags -join ',') -Target $modRoot.Name
				Build-ModInstance -Path $tempDirectory -Name $modRoot.Name -Tags $Tags -BadExtensions $BadExtensions
				
				Write-PSFMessage -Level Host -Message "    Deploying Mod" -Target $modRoot.Name
				Deploy-ModInstance -Path $tempDirectory -Name $modRoot.Name -Destination $OutPath
			}
			catch {
				Stop-PSFFunction -Message "Failed to build $($modRoot.Name)" -ErrorRecord $_ -EnableException $EnableException -Continue -Cmdlet $PSCmdlet -Target $modRoot.Name
			}
		}
	}
	end {
		Get-PSFTempItem -ModuleName PDX | Remove-PSFTempItem
	}
}