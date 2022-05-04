# Mirror List

# E.g.
# The whole download link is:
#
# https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.1.2-1/rubyinstaller-3.1.2-1-x64.7z

$RBENV_MIRRORS = @{
    Default = "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-<version>"

    # For Chinese users
    CN = "https://mirror.sjtu.edu.cn/github-release/oneclick/rubyinstaller2/releases/download/RubyInstaller-<version>"
}
