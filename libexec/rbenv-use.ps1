# Usage: rbenv use [-l|--local|-g|--global] <version>
# Summary: Set a Ruby version using local (-l) or global (-g) scope
# Category: extension
# Help: Use global scope if the current directory or a parent contains a .git
#       directory; otherwise use local scope. -l / --local and -g / --global
#       override this.
#       Options may use one or two hyphens and appear before or after the version.

$scope = $null
$version = $null

foreach ($argument in $args) {
    $argument = [string] $argument
    if ($argument -match '^--?(l|local|g|global)$') {
        if ($scope) {
            abort 'rbenv use: specify only one scope option'
        }
        if ($argument -match '^--?(l|local)$') {
            $scope = 'local'
        } else {
            $scope = 'global'
        }
    } elseif ($argument.StartsWith('-') -or $version) {
        abort 'Usage: rbenv use [-l|--local|-g|--global] <version>'
    } else {
        $version = $argument
    }
}

if (!$version) {
    abort 'Usage: rbenv use [-l|--local|-g|--global] <version>'
}

if (!$scope) {
    $scope = 'local'
    $directory = Get-Item -LiteralPath (Get-Location).Path -Force -ErrorAction Stop
    while ($directory) {
        if (Test-Path -LiteralPath (Join-Path $directory.FullName '.git') -PathType Container) {
            $scope = 'global'
            break
        }
        $directory = $directory.Parent
    }
}

command_exec $scope @($version)
