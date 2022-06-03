# rbenv patch to
#    https://github.com/ScoopInstaller/Scoop/blob/master/lib/commands.ps1
#

function get_commands {
    command_files | ForEach-Object { command_name $_ }
}


function command_files {
    (Get-ChildItem (relpath '..\libexec')) | Where-Object { $_.name -match 'rbenv-.*?\.ps1$' }
}


function command_name($filename) {
    $filename.name | Select-String 'rbenv-(.*?)\.ps1$' | ForEach-Object { $_.matches[0].groups[1].value }
}

function command_path($cmd) {
    $cmd_path = relpath "..\libexec\rbenv-$cmd.ps1"
    $cmd_path
}

function command_exec($cmd, $arguments) {
    $cmd_path = command_path $cmd

    & $cmd_path @arguments
}
