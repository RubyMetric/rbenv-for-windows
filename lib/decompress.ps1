# rbenv patch to
#    https://github.com/ScoopInstaller/Scoop/blob/master/lib/decompress.ps1
#

function Expand-7zipArchive {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [String]
        $Path,
        [Parameter(Position = 1)]
        [String]
        $DestinationPath = (Split-Path $Path),
        [String]
        $ExtractDir,
        [Parameter(ValueFromRemainingArguments = $true)]
        [String]
        $Switches,
        [ValidateSet('All', 'Skip', 'Rename')]
        [String]
        $Overwrite,
        [Switch]
        $Removal
    )

    try {
        $7zPath = (Get-Command '7z' -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
    } catch [System.Management.Automation.CommandNotFoundException] {
        abort "`nCannot find external 7-Zip (7z.exe)`nRun 'scoop install 7zip' or install 7-Zip manually and try again."
        exit 1
    }

    $LogPath = "$(Split-Path $Path)\7zip.log"
    $ArgList = @('x', "`"$Path`"", "-o`"$DestinationPath`"", '-y')
    $IsTar = ((strip_ext $Path) -match '\.tar$') -or ($Path -match '\.t[abgpx]z2?$')
    if (!$IsTar -and $ExtractDir) {
        $ArgList += "-ir!`"$ExtractDir\*`""
    }
    if ($Switches) {
        $ArgList += (-split $Switches)
    }
    switch ($Overwrite) {
        'All' { $ArgList += '-aoa' }
        'Skip' { $ArgList += '-aos' }
        'Rename' { $ArgList += '-aou' }
    }
    $Status = Invoke-ExternalCommand $7zPath $ArgList -LogPath $LogPath
    if (!$Status) {
        abort "Failed to extract files from $Path.`nLog file:`n  $(friendly_path $LogPath)`n$(new_issue_msg $app $bucket 'decompress error')"
    }
    if (!$IsTar -and $ExtractDir) {
        movedir "$DestinationPath\$ExtractDir" $DestinationPath | Out-Null
    }
    if (Test-Path $LogPath) {
        Remove-Item $LogPath -Force
    }
    if ($IsTar) {
        # Check for tar
        $Status = Invoke-ExternalCommand $7zPath @('l', "`"$Path`"") -LogPath $LogPath
        if ($Status) {
            $TarFile = (Get-Content -Path $LogPath)[-5] -replace '.{53}(.*)', '$1' # get inner tar file name
            Expand-7zipArchive -Path "$DestinationPath\$TarFile" -DestinationPath $DestinationPath -ExtractDir $ExtractDir -Removal
        } else {
            abort "Failed to list files in $Path.`nNot a 7-Zip supported archive file."
        }
    }
    if ($Removal) {
        # Remove original archive file
        Remove-Item $Path -Force
    }
}
