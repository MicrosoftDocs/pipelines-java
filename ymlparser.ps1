
Install-Module -Name FXPSYaml -Scope CurrentUser -Force
Import-Module FXPSYaml
$yamlString = @"
anArray:
- 1
- 2
- 3
nested:
  array:
  - this
  - is
  - an
  - array
hello: world
"@
ConvertFrom-YAML $yamlString

