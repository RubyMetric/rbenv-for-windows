# Versions

Sorry for not support x86 versions. If you are interested, you can contribute to this project. Maybe you can be a maintainer, contact me please.

**NOTE**:

1. Versions before `2.4.1-1`, are built by `oneclick/RubyInstaller` not by `oneclick/RubyInstaller2`, and they may be x86. So we don't support them.

2. Theses versions use a little different url, I don't want to support them
    - 2.5.x series, <= 2.5.3-1
    - 2.4.x series, <= 2.4.5-1


**For maintainers**:

Run `ruby tool/update_versions.rb` from the repository root to regenerate the x64 and arm JSON version lists from the upstream downloads data. The JSON records include SHA256 checksums for Ruby archives and Devkit installers.
