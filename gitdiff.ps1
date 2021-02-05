$files=$(git diff-tree --no-commit-id --name-only -r $(Build.SourceVersion))
$temp=$files -split ' '
$count=$temp.Length
echo "Total changed $count files"
For ($i=0; $i -lt $temp.Length; $i++){
    $name=$temp[$i]
    echo "this is $name file"
}