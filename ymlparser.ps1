
Import-Module -Name  tools\PSYaml
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
$YamlObject = ConvertFrom-YAML $yamlString
ConvertTo-YAML $YamlObject
