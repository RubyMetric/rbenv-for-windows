# rbenv patch to
#    https://github.com/ScoopInstaller/Scoop/blob/master/lib/core.ps1
#

function ensure_path($dir) {
    if(!(test-path $dir)) { mkdir $dir > $null }
    resolve-path $dir
}


# relative to calling script
function relpath($path) {
    "$($myinvocation.psscriptroot)\$path"
}


# paths
function fname($path) { split-path $path -leaf }
function strip_ext($fname) { $fname -replace '\.[^\.]*$', '' }
function strip_filename($path) { $path -replace [regex]::escape((fname $path)) }
function strip_fragment($url) { $url -replace (new-object uri $url).fragment }


function url_filename($url) {
    (split-path $url -leaf).split('?') | Select-Object -First 1
}
# Unlike url_filename which can be tricked by appending a
# URL fragment (e.g. #/dl.7z, useful for coercing a local filename),
# this function extracts the original filename from the URL.
function url_remote_filename($url) {
    $uri = (New-Object URI $url)
    $basename = Split-Path $uri.PathAndQuery -Leaf
    If ($basename -match ".*[?=]+([\w._-]+)") {
        $basename = $matches[1]
    }
    If (($basename -notlike "*.*") -or ($basename -match "^[v.\d]+$")) {
        $basename = Split-Path $uri.AbsolutePath -Leaf
    }
    If (($basename -notlike "*.*") -and ($uri.Fragment -ne "")) {
        $basename = $uri.Fragment.Trim('/', '#')
    }
    return $basename
}


# messages
function abort($msg, [int] $exit_code=1) { write-host $msg -f red; exit $exit_code }
function error($msg) { write-host "$msg" -f darkred }
function warn($msg)  { write-host "$msg" -f darkyellow }
function info($msg)  { write-host "$msg" -f darkblue }
function success($msg) { write-host $msg -f darkgreen }


function filesize($length) {
    $gb = [math]::pow(2, 30)
    $mb = [math]::pow(2, 20)
    $kb = [math]::pow(2, 10)

    if($length -gt $gb) {
        "{0:n1} GB" -f ($length / $gb)
    } elseif($length -gt $mb) {
        "{0:n1} MB" -f ($length / $mb)
    } elseif($length -gt $kb) {
        "{0:n1} KB" -f ($length / $kb)
    } else {
        "$($length) B"
    }
}


function Invoke-ExternalCommand {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [OutputType([Boolean])]
    param (
        [Parameter(Mandatory = $true,
                   Position = 0)]
        [Alias("Path")]
        [ValidateNotNullOrEmpty()]
        [String]
        $FilePath,
        [Parameter(Position = 1)]
        [Alias("Args")]
        [String[]]
        $ArgumentList,
        [Parameter(ParameterSetName = "UseShellExecute")]
        [Switch]
        $RunAs,
        [Alias("Msg")]
        [String]
        $Activity,
        [Alias("cec")]
        [Hashtable]
        $ContinueExitCodes,
        [Parameter(ParameterSetName = "Default")]
        [Alias("Log")]
        [String]
        $LogPath
    )
    if ($Activity) {
        Write-Host "$Activity " -NoNewline
    }
    $Process = New-Object System.Diagnostics.Process
    $Process.StartInfo.FileName = $FilePath
    $Process.StartInfo.Arguments = ($ArgumentList | Select-Object -Unique) -join ' '
    $Process.StartInfo.UseShellExecute = $false
    if ($LogPath) {
        if ($FilePath -match '(^|\W)msiexec($|\W)') {
            $Process.StartInfo.Arguments += " /lwe `"$LogPath`""
        } else {
            $Process.StartInfo.RedirectStandardOutput = $true
            $Process.StartInfo.RedirectStandardError = $true
        }
    }
    if ($RunAs) {
        $Process.StartInfo.UseShellExecute = $true
        $Process.StartInfo.Verb = 'RunAs'
    }
    try {
        $Process.Start() | Out-Null
    } catch {
        if ($Activity) {
            Write-Host "error." -ForegroundColor DarkRed
        }
        error $_.Exception.Message
        return $false
    }
    if ($LogPath -and ($FilePath -notmatch '(^|\W)msiexec($|\W)')) {
        Out-File -FilePath $LogPath -Encoding Default -Append -InputObject $Process.StandardOutput.ReadToEnd()
        Out-File -FilePath $LogPath -Encoding Default -Append -InputObject $Process.StandardError.ReadToEnd()
    }
    $Process.WaitForExit()
    if ($Process.ExitCode -ne 0) {
        if ($ContinueExitCodes -and ($ContinueExitCodes.ContainsKey($Process.ExitCode))) {
            if ($Activity) {
                Write-Host "done." -ForegroundColor DarkYellow
            }
            warn $ContinueExitCodes[$Process.ExitCode]
            return $true
        } else {
            if ($Activity) {
                Write-Host "error." -ForegroundColor DarkRed
            }
            error "Exit code was $($Process.ExitCode)!"
            return $false
        }
    }
    if ($Activity) {
        Write-Host "done." -ForegroundColor Green
    }
    return $true
}


function version_match_regexp {
    # '\d{1,}\.\d{1,}\.\d{1,}-\d{1,}.*?$'
    '\d{1,}\.\d{1,}\.\d{1,}-\d{1,}'
}
