# relative to calling script
function relpath($path) {
    "$($myinvocation.psscriptroot)\$path"
}
