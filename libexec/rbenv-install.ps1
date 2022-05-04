# rbenv patch to
#    https://github.com/ScoopInstaller/Scoop/blob/master/lib/install.ps1
#

# Usage: rbenv install <version>
# Summary: Install a Ruby version using RubyInstaller2
# Help: rbenv install 3.1.2-1  => Install RubyInstaller 3.1.2-1
# rbenv install 3.1.2    => Install the latest packaged version of 3.1.2
# rbenv install msys     => Install latest MSYS2, must-have for Gem with C extension
# rbenv install msys2    => same with 'install msys'


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


# Download the latest x64 msys2
# The 64-bit version msys2 is able to build both 32-bit and 64-bit packages
#
# Sorry, I don't have time to support using x86 msys2
# If you want, just fork it
#
# Why we don't use scoop to install msys2 directly?
# I must say, if you directly install via scoop,
# RubyInstaller will cause more time to find it, that's too bad.
# And we don't want to depend on other softwares too.
#
# We offer the best way to coordinate with RubyInstaller2
# ------------------------------------------------------------------
#
# The user will download in three ways
#   1. Download directly from official MSYS2 official repos
#
#   2. User uses a self assigned mirror
#           $env:RBENV_USE_MSYS2_MIRROR = "https://abc.com"
#
#   3. User uses our authenticated mirrors directly
#           $env:RBENV_USE_MSYS2_MIRROR = "CN"  # e.g. For Chinese users
#
# See share/msys2-mirrors.ps1
function download_msys2 {
    # Get our mirror list
    . $PSScriptRoot\..\share\msys2-mirrors.ps1

    $mir = $env:RBENV_USE_MSYS2_MIRROR
    if ($mir) {
        if ($mir -contains "http" ) { $site_url = $mir }
        else { $site_url = $RBENV_MSYS2_MIRRORS["$mir"] }
        info "Using mirror for downloading MSYS2: "
        info "$site_url"
    } else {
        $site_url = $RBENV_MSYS2_MIRRORS['Default']
    }

    $relative = "/distrib/msys2-x86_64-latest.exe"
    $url = $site_url + $relative
    $cache_name = "msys2-x86_64-latest.exe"

    return download_with_cache $url $cache_name
}


# The user will download in three ways
#   1. Download directly from official RubyInstaller2 Github release
#
#   2. User uses a self assigned mirror
#           $env:RBENV_USE_RUBY_MIRROR = "https://abc.com/abc-<version>"
#
#   3. User uses our authenticated mirrors directly
#           $env:RBENV_USE_RUBY_MIRROR = "CN"  # e.g. For Chinese users
#
# See share/ruby-mirrors.ps1
function download_rubyinstaller($version) {
    # Get our mirror list
    . $PSScriptRoot\..\share\ruby-mirrors.ps1

    $mir = $env:RBENV_USE_RUBY_MIRROR
    if ($mir) {
        if ($mir -contains "http" ) { $site_url = $mir }
        else { $site_url = $RBENV_RUBY_MIRRORS["$mir"] }
        info "Using mirror for downloading RubyInstaller2: "
        info "$site_url"

    } else {
        $site_url = $RBENV_RUBY_MIRRORS['Default']
    }

    $url = $site_url -replace '<version>', $version

    $cache_name = "rubyinstaller-$version-x64.7z"
    $url += "/$cache_name"

    # Write-Host "$url"
    return download_with_cache $url $cache_name
}


function install_msys2 {
    $path = download_msys2
    Write-Host "Installing..."
    & $path in --confirm-command --accept-messages --root $env:RBENV_ROOT\msys64
    success "MSYS2 was installed successfully!"
}


function install_rubyinstaller($version) {
    . $PSScriptRoot\..\lib\decompress.ps1

    if ($(get_all_installed_versions) -contains $version) {
        warn "version $version is already installed."
    } else {
        $path = download_rubyinstaller $version
        $dir_in_7z = strip_ext (fname $path)

        Write-Host "Installing..."
        Expand-7zipArchive $path $env:RBENV_ROOT

        Move-Item "$env:RBENV_ROOT\$dir_in_7z" "$env:RBENV_ROOT\$version"
        success "$version was installed successfully!"
    }
}


if (!$cmd) {
    rbenv help install
} elseif ($cmd -eq "msys" -or $cmd -eq "msys2" ) {
    install_msys2
} else {
    install_rubyinstaller($cmd)
}
