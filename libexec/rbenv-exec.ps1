# Usage: rbenv exec <command> [<args>...]
# Summary: Run a command using the current rbenv environment
# Help: Run a command directly; rbenv's shims select the Ruby version.

if ($args.Count -eq 0 -or -not $args[0]) {
    [Console]::Error.WriteLine('Usage: rbenv exec <command> [<args>...]')
    exit 1
}

$command = $args[0]
$arguments = @($args | Select-Object -Skip 1)

if ($env:RBENV_INIT -ne 1) {
    if (-not $env:RBENV_ROOT) {
        [Console]::Error.WriteLine('rbenv: environment variable RBENV_ROOT must be set')
        exit 1
    }

    & {
        $ErrorActionPreference = 'Stop'
        & "$PSScriptRoot\..\bin\rbenv.ps1" init
    }
}

# The Ruby and Gem shims already select the active version.
# So all we need to do is to forward it.
& $command @arguments
if (-not $?) {
    if ($LASTEXITCODE -eq 0) { exit 1 }
    exit $LASTEXITCODE
}
