# Usage: rbenv help <command>
# Summary: Show help for a command

param($cmd)

function print_help {
  $file = Get-Content (command_path $cmd) -raw

  $usage = usage $file
  $summary = summary $file
  $help = scoop_help $file

    if($usage) { "$usage`n" }
    if($help) { $help }

}