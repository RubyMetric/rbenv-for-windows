# I write this in PowerShell rather than Rakefile to avoid Ruby in the worst case

function build_fake_ruby() {
    dmd -of=.\bin\ruby.exe .\bin\source\ruby.d .\bin\source\rbenv.d
}

function build_rbenv_rehash() {
    dmd -of=.\libexec\rbenv-rehash.exe .\bin\source\rbenv-rehash.d .\bin\source\rbenv.d
}


Write-Host "rbenv: Build fake ruby.exe to .\bin\"
build_fake_ruby
Write-Host "rbenv: Build rbenv-rehash.exe to .\libexec\"
build_rbenv_rehash
