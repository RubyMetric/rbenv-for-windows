
function get_commands {
  $command_files = (Get-ChildItem (relpath '..\libexec')) `
    | Where-Object { $_.name -match 'rbenv-.*?\.ps1$' }

  $command_files | ForEach-Object { command_name $_ }
}


function command_name($filename) {
  $filename.name | Select-String 'rbenv-(.*?)\.ps1$' | ForEach-Object { $_.matches[0].groups[1].value }
}


function exec($cmd, $arguments) {
  $cmd_path = relpath "..\libexec\scoop-$cmd.ps1"

  & $cmd_path @arguments
}
