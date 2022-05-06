# Usage: rbenv whence [<executable>]
# Summary: List all Ruby versions that contain the given executable


param($cmd)


function try_suffix ($where, $name) {

    $suffixes = @( "ps1", "exe", "bat", "cmd" )

    foreach ($s in $suffixes) {
        $any = Get-ChildItem $where "$name.$s"
        if ($any) { return "$where\$name.$s" }
    }
    return $null
}


function list_who_has ($name) {

    $versions = get_all_installed_versions

    $whos = @()

    foreach ($ver in $versions) {
        if ($ver -eq 'system') {
            $_, $where = get_system_ruby_version_and_path
            $where = "$where\bin"
        } else {
            $where = "$env:RBENV_ROOT\$ver\bin"
        }
        $who = try_suffix $where $name
        if ($who) { $whos += $who }
        else { continue }
    }

    if ($whos.Count -gt 0) {
        return $whos
    } else {
        warn "rbenv: $name`: command not found"
    }
}


if (!$cmd) {
    rbenv help whence
} else {
    list_who_has($cmd)
}
