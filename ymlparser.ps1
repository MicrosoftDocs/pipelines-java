Install-Module -Name FXPSYaml -Scope CurrentUser -Force
Import-Module FXPSYaml
[string[]]$fileContent = Get-Content "$PSScriptRoot\test.yml"
$content = ''
foreach ($line in $fileContent) { $content = $content + "`n" + $line }
$yaml = ConvertFrom-YAML $content
$yaml
Write-Host ("Account name is " + $yaml.testconfig.accountType)
$accountTypeVal = $yaml.testconfig.accountType
Write-Host '##vso[task.setvariable variable=accountType;]'$accountTypeVal

