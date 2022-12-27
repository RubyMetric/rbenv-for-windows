# rbenv patch to
#    https://github.com/ScoopInstaller/Scoop/blob/master/lib/install.ps1
#

# Usage: rbenv install <version>
# Summary: Install a Ruby version using RubyInstaller2
# Help: rbenv install head     => Install the daily-updated version of the Ruby dev branch
# rbenv install -l       => List recent versions
# rbenv install -a       => List all versions
# rbenv install 3.1.2-1  => Install RubyInstaller 3.1.2-1
# rbenv install 3.1.2    => Install the latest packaged version of 3.1.2
# rbenv install msys     => Install shared MSYS2(latest), must-have for Gem with C extension
# rbenv install msys2    => same with 'install msys'
# rbenv install devkit   => same with 'install msys'


param($cmd)

# e.g.
# Scoop/1.0 (+http://scoop.sh/) PowerShell/7.2 (Windows NT 10.0; Win64; x64; Core)
function Get-UserAgent() {
    return "Scoop/1.0 (+http://scoop.sh/) PowerShell/$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor) (Windows NT $([System.Environment]::OSVersion.Version.Major).$([System.Environment]::OSVersion.Version.Minor); $(if($env:PROCESSOR_ARCHITECTURE -eq 'AMD64'){'Win64; x64; '})$(if($env:PROCESSOR_ARCHITEW6432 -eq 'AMD64'){'WOW64; '})$PSEdition)"
}


function cookie_header($cookies) {
    if(!$cookies) { return }

    $vals = $cookies.psobject.properties | ForEach-Object {
        "$($_.name)=$($_.value)"
    }

    [string]::join(';', $vals)
}


# used in dl_progress
function dl_progress_output($url, $read, $total, $console) {
    $filename = url_remote_filename $url

    # calculate current percentage done
    $p = [math]::Round($read / $total * 100, 0)

    # pre-generate LHS and RHS of progress string
    # so we know how much space we have
    $left  = "$filename ($(filesize $total))"
    $right = [string]::Format("{0,3}%", $p)

    # calculate remaining width for progress bar
    $midwidth  = $console.BufferSize.Width - ($left.Length + $right.Length + 8)

    # calculate how many characters are completed
    $completed = [math]::Abs([math]::Round(($p / 100) * $midwidth, 0) - 1)

    # generate dashes to symbolise completed
    if ($completed -gt 1) {
        $dashes = [string]::Join("", ((1..$completed) | ForEach-Object {"="}))
    }

    # this is why we calculate $completed - 1 above
    $dashes += switch($p) {
        100 {"="}
        default {">"}
    }

    # the remaining characters are filled with spaces
    $spaces = switch($dashes.Length) {
        $midwidth {[string]::Empty}
        default {
            [string]::Join("", ((1..($midwidth - $dashes.Length)) | ForEach-Object {" "}))
        }
    }

    "$left [$dashes$spaces] $right"
}


# Used in dl to show progress
function dl_progress($read, $total, $url) {
    $console = $host.UI.RawUI;
    $left  = $console.CursorPosition.X;
    $top   = $console.CursorPosition.Y;
    $width = $console.BufferSize.Width;

    if($read -eq 0) {
        $maxOutputLength = $(dl_progress_output $url 100 $total $console).length
        if (($left + $maxOutputLength) -gt $width) {
            # not enough room to print progress on this line
            # print on new line
            write-host
            $left = 0
            $top  = $top + 1
            if($top -gt $console.CursorPosition.Y) { $top = $console.CursorPosition.Y }
        }
    }

    write-host $(dl_progress_output $url $read $total $console) -nonewline
    [console]::SetCursorPosition($left, $top)
}


# download with filesize and progress indicator
function dl($url, $to, $cookies, $progress) {
    $reqUrl = ($url -split "#")[0]
    $wreq = [net.webrequest]::create($reqUrl)
    if($wreq -is [net.httpwebrequest]) {
        $wreq.useragent = Get-UserAgent
        if (-not ($url -imatch "sourceforge\.net" -or $url -imatch "portableapps\.com")) {
            $wreq.referer = strip_filename $url
        }
        if($cookies) {
            $wreq.headers.add('Cookie', (cookie_header $cookies))
        }
    }

    try {
        $wres = $wreq.GetResponse()
    } catch [System.Net.WebException] {
        $exc = $_.Exception
        $handledCodes = @(
            [System.Net.HttpStatusCode]::MovedPermanently,  # HTTP 301
            [System.Net.HttpStatusCode]::Found,             # HTTP 302
            [System.Net.HttpStatusCode]::SeeOther,          # HTTP 303
            [System.Net.HttpStatusCode]::TemporaryRedirect  # HTTP 307
        )

        # Only handle redirection codes
        $redirectRes = $exc.Response
        if ($handledCodes -notcontains $redirectRes.StatusCode) {
            throw $exc
        }

        # Get the new location of the file
        if ((-not $redirectRes.Headers) -or ($redirectRes.Headers -notcontains 'Location')) {
            throw $exc
        }

        $newUrl = $redirectRes.Headers['Location']
        info "Following redirect to $newUrl..."

        # Handle manual file rename
        if ($url -like '*#/*') {
            $null, $postfix = $url -split '#/'
            $newUrl = "$newUrl#/$postfix"
        }

        dl $newUrl $to $cookies $progress
        return
    }

    $total = $wres.ContentLength
    # rbenv: we don't use ftp
    # if($total -eq -1 -and $wreq -is [net.ftpwebrequest]) {
    #   $total = ftp_file_size($url)
    # }

    # Define inner function dl_onProgress
    if ($progress -and ($total -gt 0)) {
        [console]::CursorVisible = $false
        function dl_onProgress($read) {
            dl_progress $read $total $url
        }
    } else {
        write-host "Downloading $url ($(filesize $total))..."
        function dl_onProgress {
            #no op
        }
    }

    try {
        $s = $wres.getresponsestream()
        $fs = [io.file]::openwrite($to)
        $buffer = new-object byte[] 2048
        $totalRead = 0
        $sw = [diagnostics.stopwatch]::StartNew()

        dl_onProgress $totalRead
        while(($read = $s.read($buffer, 0, $buffer.length)) -gt 0) {
            $fs.write($buffer, 0, $read)
            $totalRead += $read
            if ($sw.elapsedmilliseconds -gt 100) {
                $sw.restart()
                dl_onProgress $totalRead
            }
        }
        $sw.stop()
        dl_onProgress $totalRead
    } finally {
        if ($progress) {
            [console]::CursorVisible = $true
            write-host
        }
        if ($fs) {
            $fs.close()
        }
        if ($s) {
            $s.close();
        }
        $wres.close()
    }
}


function download($url, $to, $cookies = $null) {
    # True of False
    $progress = [console]::isoutputredirected -eq $false -and
        $host.name -ne 'Windows PowerShell ISE Host'

    try {
        dl $url $to $cookies $progress
    } catch {
        $e = $_.exception
        if($e.innerexception) { $e = $e.innerexception }
        throw $e
    }
}


# call-seq:
# download_with_cache (reuse cache)
#   download (try)
#     dl (real download work)
#       dl_onProgress (inner defined)
#         dl_progress (show progress)
#           dl_progress_output (real progress work)
function download_with_cache($url, $cache_name, $to = $null) {

    $RBENV_CACHE_DIR = "$env:RBENV_ROOT\cache"

    $cached = "$RBENV_CACHE_DIR\$cache_name"

    if(!(Test-Path $cached)) {
        ensure_path $RBENV_CACHE_DIR | Out-Null
        # We don't use cookies
        download $url "$cached.download"
        Move-Item "$cached.download" $cached -force
    } else {
        write-host "Loading $(url_remote_filename $url) from cache"
    }

    if (!($null -eq $to)) {
        Copy-Item $cached $to
        return $to
    }

    return $cached
}



# Prevent it to be system Ruby
function remove_ruby_registry_info($version) {
    # HKEY_CURRENT_USER
    $install_keys = "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    $keys = (Get-Item "$install_keys\RubyInstaller*")
    foreach ($k in $keys) {
        if ($k.GetValue("DisplayVersion") -eq $version) {
            # Remove-Item $k # This is wrong
            $k | Remove-Item
            success "rbenv: remove version $version registry info "
        }
    }
}




# The user will download in three ways
#   1. Download directly from official RubyInstaller2 Github release
#
#   2. User uses a self assigned mirror
#           $env:RBENV_USE_MIRROR = "https://abc.com/abc-<version>"
#
#   3. User uses our authenticated mirrors directly
#           $env:RBENV_USE_MIRROR = "CN"  # e.g. For Chinese users
#
# See share/mirrors.ps1
# ------------------------------------------------------------------
#
# From 3.1.0-1, we should download rubyinstaller-<version>.7z directly, no devkit!
# That's only about less than 15MB. Every Ruby share one MSYS64!
#
# However, below 3.1.0-1, we have to download rubyinstaller-devkit-<version>.7z, with devkit!
# That's about 100MB ... Every Ruby has their own MSYS64!
#
# Why?
#
# Note that from 3.1.0-1, all Rubies are [x64-mingw-ucrt]
# before that, all Rubies are [x64-mingw32]
#
# The former uses 'ucrt64'  toolchain
# The latter uses 'mingw64' toolchain
#
# They may not be compatible, for users who just want enjoy everything ready (they can directly
# build gems with C extensions), we have to do this.
#
# In brief:
#   1. Install whole rubyinstaller-devkit.7z in 'version < 3.1.0-1'
#   2. Install only  rubyinstaller.7z in 'version >= 3.1.0-1'
#
function download_ruby($version) {
    # Get our mirror list
    . $PSScriptRoot\..\share\mirrors.ps1

    $mir = $env:RBENV_USE_MIRROR
    if ($mir) {
        if ($mir -contains "http" ) { $site_url = $mir.TrimEnd('/') }
        else { $site_url = $RBENV_MIRRORS["$mir"] }
        info "Using mirror for downloading RubyInstaller.7z "

    } else {
        $site_url = $RBENV_MIRRORS['Default']
    }

    $url = $site_url -replace '<version>', $version

    $cache_name = "rubyinstaller-$version-x64.7z"
    $url += "/$cache_name"

    if ($version -eq 'head') {
        warn "rbenv: The 'head' version can only be downloaded from Github"
        $url = "https://github.com/oneclick/rubyinstaller2/releases/download/rubyinstaller-head/rubyinstaller-head-x64.7z"
    }

    Write-Host "Begin downloading ..."
    info "=> $url"
    return download_with_cache $url $cache_name
}


function install_ruby($version) {
    . $PSScriptRoot\..\lib\decompress.ps1

    $version = auto_fix_version_for_remote $version

    if ($(get_all_installed_versions) -contains $version) {
        warn "version $version is already installed."
        exit
    }

    if ($version -lt '3.1.0-1') {
        warn "version < '3.1.0-1' need mingw64 toolchain (Not compatible with our shared MSYS2's ucrt64 toolchain)"
        warn "Only full version can make you install a gem with C extensions`n"

        Write-Host "  1. Lite version $version (less than 15MB) [Default]"
        Write-Host "  2. Full version $version-with-devkit? (at least 130MB)`n"

        $choice = Read-Host -Prompt "Which one?"
        # Not $null, but ""
        if ("" -eq $choice -or $choice -eq 1) {
            # go on
        } else {
            install_ruby_with_msys2 $version
            exit
        }
    }

    $path = download_ruby $version
    $dir_in_7z = strip_ext (fname $path)

    Write-Host "Installing $version ..."
    Expand-7zipArchive $path $env:RBENV_ROOT

    Move-Item "$env:RBENV_ROOT\$dir_in_7z" "$env:RBENV_ROOT\$version"

    rbenv rehash version $version
    success "version '$version' was installed successfully!"

    if ($version -eq 'head') {
        Remove-Item $path
        success "success remove the 'head' version cache"
    }
}



# Only called by install_ruby_with_msys2
function download_ruby_with_msys2($version) {
        # Get our mirror list
    . $PSScriptRoot\..\share\mirrors.ps1

    $mir = $env:RBENV_USE_MIRROR
    if ($mir) {
        if ($mir -contains "http" ) { $site_url = $mir.TrimEnd('/') }
        else { $site_url = $RBENV_MIRRORS["$mir"] }
        info "Using mirror for downloading RubyInstaller-devkit(MSYS2): "
    } else {
        $site_url = $RBENV_MIRRORS['Default']
    }

    $url = $site_url -replace '<version>', $version

    $cache_name = "rubyinstaller-devkit-$version-x64.exe"
    $url += "/$cache_name"

    Write-Host "Begin downloading ..."
    info "=> $url"
    return download_with_cache $url $cache_name
}



# Only called by install_ruby
# For versions < 3.1.0-1
function install_ruby_with_msys2($version) {
    $path = download_ruby_with_msys2 $version

    # e.g. rubyinstaller-devkit-3.1.2-1-x64
    $target = fname $path
    Write-Host "Installing $target ..."

    $version = $target | Select-String $(version_match_regexp)

    $version = $version.Matches[0].value

    # Ref: https://github.com/oneclick/rubyinstaller2/wiki/FAQ#user-content-silent-install

    # No /tasks=assocfiles,modpath,defaultutf8
    # the defaultutf8 will register a env var 'RUBYOPT': -Eutf-8
    # Use a portable way!
    $ArgList = @("/verysilent", "/dir=$env:RBENV_ROOT\$version", "/tasks=defaultutf8")
    $Status = Invoke-ExternalCommand $path $ArgList
    if (!$Status) {
        abort "Failed to install to $version"
    }

    rbenv rehash version $version
    remove_ruby_registry_info $version

    success "version '$version' with devkit was installed successfully!"
}


# Download the latest x64 MSYS2 built into official RubyInstaller-devkit
#
# The 64-bit version MSYS2 is able to build both 32-bit and 64-bit packages
#
#
# Sorry, I don't have time to support using x86 MSYS2
# If you want, think about how to improve and fork it
#
#
# So why we don't use scoop to install msys2 directly?
#
#   1. I must say, if you directly install it via scoop,
#      RubyInstaller2 will cause more time to find it,
#      that's too bad.
#   2. We don't want to depend on other softwares too.
#   3. A pure MSYS2 installation will let user download
#      dependencies locally, which will cause more time
#      and may cause other issues.
#   4. Reuse the work results of RubyInstaller build
#      process. oneclick/RubyInstaller2 has already done
#      lots of trivial works for users to setup MSYS2.
#      Everyone can thus get the same(with upstream) and
#      a quite stable environment.
#
# We offer the best way to coordinate with RubyInstaller2
# ------------------------------------------------------------------
#
# See share/mirrors.ps1
function download_shared_msys2 {
    $all = get_all_remote_versions
    $installed = get_all_installed_versions

    # use latest stable build, rather than head, rather than what has been installed
    $version = $null
    foreach ($i in $all) {
        if ($i -eq 'head' ) { continue }
        if ($installed -contains $i) { continue }
        $version = $i
        break
    }
    return download_ruby_with_msys2 $version
}


function install_shared_msys2 {

    if (Test-Path "$env:RBENV_ROOT\msys64") {
        warn "rbenv: Already exists the shared msys64 ("$env:RBENV_ROOT\msys64")"
        exit
    }

    $path = download_shared_msys2

    # e.g. rubyinstaller-devkit-3.1.2-1-x64
    $target = fname $path
    Write-Host "Installing $target(MSYS2) ..."

    $version = $target | Select-String $(version_match_regexp)

    $version = $version.Matches[0].value

    # No /tasks=assocfiles,modpath,defaultutf8
    # the defaultutf8 will register a env var 'RUBYOPT': -Eutf-8
    # Use a portable way!
    $ArgList = @("/verysilent", "/dir=$env:RBENV_ROOT\$version")
    $Status = Invoke-ExternalCommand $path $ArgList
    if (!$Status) {
        abort "Failed to install to $version"
    }

    Write-Host "Moving the shared MSYS2 ..."
    Move-Item "$env:RBENV_ROOT\$version\msys64" "$env:RBENV_ROOT"

    rbenv rehash version $version

    remove_ruby_registry_info $version

    success "The shared MSYS2 was installed successfully!"
    success "In addition, version '$version' was installed for you!"
}





# Hi, dear maintainers, you may be wondering how I decide to download.
#
#              -- if version >= 3.1.0-1, just download rubyinstaller.7z
# install_ruby |
#              -- if version < 3.1.0-1,  we want a rubyinstaller-devkit.7z. But at present,
#                 the upstream doesn't offer this. So we will prompt for user, let the user
#                 decide a lite version or a full version (with MSYS2). If latter, we need
#                 to download rubyinstaller-devkit.exe and install it, then remove its
#                 modification to the registry (prevent it to be a system Ruby)
#
# install_shared_msys2 -
#                It will not download a pure msys2. Instead, we will download a latest but
#                not head version of rubyinstaller-devkit.exe. Install it, and move the
#                msys64 dir out of it to be the shared MSYS2. Then remove its modification to
#                the registry (prevent it to be a system Ruby)
#
#
# As you can see, we must deal with registry, this is hacking.
# So once the upstream can offer help, we will live a happy maintaining life.
#
# See:  https://github.com/oneclick/rubyinstaller2/issues/281
#



if ($args[0] -eq '-l' -or $args[0] -eq '--list') {
    $versions = get_all_remote_versions
    $versions[0..10]
}

elseif ($args[0] -eq '-a' -or $args[0] -eq '--all') {
    get_all_remote_versions
}

elseif (!$cmd) {
    rbenv help install
}

elseif ($cmd -eq "msys" -or $cmd -eq "msys2" -or $cmd -eq "devkit" ) {
    install_shared_msys2
}

else {
    install_ruby($cmd)
}
