# Usage: rbenv help <command>
# Summary: Show help for a command

param($cmd)

function usage($text) {
    $text | Select-String '(?m)^# Usage: ([^\n]*)$' | ForEach-Object {
        "Usage: " + $_.matches[0].groups[1].value
    }
}

function summary($text) {
    $text | Select-String '(?m)^# Summary: ([^\n]*)$' | ForEach-Object {
         $_.matches[0].groups[1].value
    }
}

function rbenv_help($text) {
    $help_lines = $text | Select-String '(?ms)^# Help:(.(?!^[^#]))*' | ForEach-Object {
         $_.matches[0].value;
    }
    $help_lines -replace '(?ms)^#\s?(Help: )?', ''
}

function my_usage { # gets usage for the calling script
    usage (Get-Content $myInvocation.PSCommandPath -raw)
}


function print_help {
    $file = Get-Content (command_path $cmd) -raw

    $usage = usage $file
    $summary = summary $file
    $help = rbenv_help $file

    if($usage) { "$usage`n" }
    if($help) { $help }
}


function print_summaries {
    $commands = @{}
    $extensions = @{}

    command_files | ForEach-Object {
        $command = command_name $_
        $text = Get-Content (command_path $command) -raw
        $summary = summary $text
        if(!($summary)) { $summary = '' }
        if ($text -match '(?m)^# Category: extension\r?$') {
            $extensions.add("$command ", $summary)
        } else {
            $commands.add("$command ", $summary)
        }
    }

    $commands.getenumerator() | Sort-Object name | Format-Table -hidetablehead -autosize -wrap
    if ($extensions.Count -gt 0) {
        "`nExtended commands by rbenv for Windows:"
        $extensions.getenumerator() | Sort-Object name | Format-Table -hidetablehead -autosize -wrap
    }
}

$available_commands = get_commands


if(!($cmd)) {
    "Usage: rbenv <command> [<args>]
Some useful commands are:"
    print_summaries
    "Type 'rbenv help <command>' to get help for a specific command."
} elseif($available_commands -contains $cmd) {
    print_help $cmd
} else {
    "rbenv help: no such command '$cmd'"; exit 1
}
