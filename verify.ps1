#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '4.0.8' }

[CmdletBinding()]
param
(
    [Parameter(Mandatory = $false)]
    [System.String]
    $Name = '*'
)

# Import the config file
$config = Get-Content -Path "$PSScriptRoot\verify.json" -Raw | ConvertFrom-Json

# Template path
$templatePath = Join-Path -Path $PSScriptRoot -ChildPath 'Template'

# Convert the template content to test
function Get-TemplateContent($Path, $RepoName)
{
    $content = Get-Content -Path $Path -Raw

    $content = $content.Replace('<# YEAR #>', [DateTime]::Now.Year)
    $content = $content.Replace('<# MODULE NAME #>', $RepoName)

    $content = $content -replace '\<\#\ [A-Z ]*\ \#\>', '§§§'
    $content = [Regex]::Escape($content)
    $content = $content.Replace('§§§', '[\s\S]*')

    Write-Output $content
}

# Pester tests to verify module integrity
Describe 'PowerShell Modules' {

    foreach ($repo in $config)
    {
        $repoName        = $repo.Name
        $repoPath        = $repo.Path
        $repoLicense     = $repo.License
        $repoRepository  = $repo.Repository
        $repoBuildSystem = $repo.BuildSystem

        $moduleNames = Join-Path -Path $repoPath -ChildPath 'Modules' | Get-ChildItem -ErrorAction SilentlyContinue | Select-Object -ExpandProperty 'BaseName'
        $sourceNames = Join-Path -Path $repoPath -ChildPath 'Sources1' | Get-ChildItem -ErrorAction SilentlyContinue | Select-Object -ExpandProperty 'BaseName'

        if ($repoName -like $Name)
        {
            Context "Repository $repoName" {

                It 'should exist on the file system' {

                    # Act, Assert
                    Test-Path -Path $repoPath | Should -Be $true
                }

                It 'should have a valid /.gitignore' {

                    # Arrange
                    $filePath = Join-Path -Path $repoPath -ChildPath '.gitignore'

                    # Act
                    $fileExist = Test-Path -Path $filePath

                    # Assert
                    $fileExist | Should -Be $true
                    $filePath  | Should -FileContentMatchMultiline '/bin/'
                    $filePath  | Should -FileContentMatchMultiline '/tst/'
                }

                if ($repoBuildSystem -eq 'AppVeyor')
                {
                    It 'should have a valid /appveyor.yml' {

                        # Arrange
                        $filePath = Join-Path -Path $repoPath -ChildPath 'appveyor.yml'

                        # Act
                        $fileExist   = Test-Path -Path $filePath
                        $fileContent = Get-TemplateContent -Path "$templatePath\appveyor.yml" -RepoName $repoName

                        # Assert
                        $fileExist | Should -Be $true
                        $filePath  | Should -FileContentMatchMultiline $fileContent
                    }
                }

                if ($repoBuildSystem -eq 'GitLab')
                {
                    It 'should have a valid /.gitlab-ci.yml' {

                        # Arrange
                        $filePath = Join-Path -Path $repoPath -ChildPath '.gitlab-ci.yml'

                        # Act
                        $fileExist   = Test-Path -Path $filePath
                        $fileContent = Get-TemplateContent -Path "$templatePath\.gitlab-ci.yml" -RepoName $repoName

                        # Assert
                        $fileExist | Should -Be $true
                        $filePath  | Should -FileContentMatchMultiline $fileContent
                    }
                }

                It 'should have a valid /build.psake.ps1' {

                    # Arrange
                    $filePath = Join-Path -Path $repoPath -ChildPath 'build.psake.ps1'

                    # Act
                    $fileExist   = Test-Path -Path $filePath
                    $fileContent = Get-TemplateContent -Path "$templatePath\build.psake.ps1" -RepoName $repoName

                    # Assert
                    $fileExist | Should -Be $true
                    $filePath  | Should -FileContentMatchMultiline $fileContent
                }

                It 'should have a valid /build.settings.ps1' {

                    # Arrange
                    $filePath = Join-Path -Path $repoPath -ChildPath 'build.settings.ps1'

                    # Act
                    $fileExist   = Test-Path -Path $filePath
                    $fileContent = Get-TemplateContent -Path "$templatePath\build.settings.ps1" -RepoName $repoName

                    # Assert
                    $fileExist | Should -Be $true
                    $filePath  | Should -FileContentMatchMultiline $fileContent
                }

                It 'should have a valid /CHANGELOG.md' {

                    # Arrange
                    $filePath = Join-Path -Path $repoPath -ChildPath 'CHANGELOG.md'

                    # Act
                    $fileExist   = Test-Path -Path $filePath
                    $fileLines   = Get-Content -Path $filePath
                    $fileContent = Get-TemplateContent -Path "$templatePath\CHANGELOG.md" -RepoName $repoName

                    # Assert
                    $fileExist | Should -Be $true
                    $filePath  | Should -FileContentMatchMultiline $fileContent
                    for ($i = 7; $i -lt $fileLines.Count; $i++)
                    {
                        $fileLines[$i] | Should -Match '(^$)|(^## Unreleased$)|(^## \d*\.\d*\.\d* - \d{4}-\d{2}-\d{2}$)|(^\* (Added|Changed|Deprecated|Removed|Fixed|Security): .*$)|(^\ \ .*$)'
                    }
                }

                It 'should have a valid /LICENSE' {

                    # Arrange
                    $filePath = Join-Path -Path $repoPath -ChildPath 'LICENSE'

                    # Act
                    $fileExist   = Test-Path -Path $filePath
                    $fileContent = Get-TemplateContent -Path "$templatePath\LICENSE`~$repoLicense" -RepoName $repoName

                    # Assert
                    $fileExist | Should -Be $true
                    $filePath  | Should -FileContentMatchMultiline $fileContent
                }

                It 'should have a valid /README.md' {

                    # Arrange
                    $filePath = Join-Path -Path $repoPath -ChildPath 'README.md'

                    # Act
                    $fileExist   = Test-Path -Path $filePath
                    $fileContent = Get-TemplateContent -Path "$templatePath\README`~$repoRepository.md" -RepoName $repoName

                    # Assert
                    $fileExist | Should -Be $true
                    $filePath  | Should -FileContentMatchMultiline $fileContent
                }

                Context 'Visual Studio Code' {

                    It 'should have a valid /.vscode/launch.json' -Pending {
                    }

                    It 'should have a valid /.vscode/settings.json' {

                        # Arrange
                        $filePath = Join-Path -Path $repoPath -ChildPath '.vscode\settings.json'

                        # Act
                        $fileExist   = Test-Path -Path $filePath
                        $fileContent = Get-TemplateContent -Path "$templatePath\.vscode\settings.json" -RepoName $repoName

                        # Assert
                        $fileExist | Should -Be $true
                        $filePath  | Should -FileContentMatchMultiline $fileContent
                    }

                    It 'should have a valid /.vscode/tasks.json' {

                        # Arrange
                        $filePath = Join-Path -Path $repoPath -ChildPath '.vscode\tasks.json'

                        # Act
                        $fileExist   = Test-Path -Path $filePath
                        $fileContent = Get-TemplateContent -Path "$templatePath\.vscode\tasks.json" -RepoName $repoName

                        # Assert
                        $fileExist | Should -Be $true
                        $filePath  | Should -FileContentMatchMultiline $fileContent
                    }
                }

                foreach ($moduleName in $moduleNames)
                {
                    Context "Module $moduleName" {

                        It "should have a valid /Modules/$moduleName/$moduleName.psd1" {

                            # Arrange
                            $filePath = Join-Path -Path $repoPath -ChildPath "Modules/$moduleName/$moduleName.psd1"

                            # Act
                            $fileExist   = Test-Path -Path $filePath
                            $fileContent = Get-TemplateContent -Path "$templatePath\Modules\Dummy\Dummy.psd1" -RepoName $repoName

                            # Assert
                            $fileExist | Should -Be $true
                            $filePath  | Should -FileContentMatchMultiline $fileContent
                        }

                        It "should have a valid /Modules/$moduleName/$moduleName.psm1" {

                            # Arrange
                            $filePath = Join-Path -Path $repoPath -ChildPath "Modules/$moduleName/$moduleName.psm1"

                            # Act
                            $fileExist   = Test-Path -Path $filePath
                            $fileContent = Get-TemplateContent -Path "$templatePath\Modules\Dummy\Dummy.psm1" -RepoName $repoName

                            # Assert
                            $fileExist | Should -Be $true
                            $filePath  | Should -FileContentMatchMultiline $fileContent
                        }
                    }
                }

                foreach ($sourceName in $sourceNames)
                {
                    Context "Source $sourceName" {

                    }
                }
            }
        }
    }
}
