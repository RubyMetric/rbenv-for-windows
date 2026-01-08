# Before release

1. Run `./tool/build.ps1 -Release -Export` to generate binaries

2. Change `./bin/rbenv.ps1` version number

3. Run `chlog` to update `CHANGELOG.md`

4. `git tag -a vx.y.z -m "Release vx.y.z"`

5. Draft a new release `vx.y.z` on GitHub and Gitee

6. Update tag `latest-binary` release on GitHub and Gitee
