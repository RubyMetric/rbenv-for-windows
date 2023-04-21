/* --------------------------------------------------------------
* File          : ruby.d
* Authors       : Aoran Zeng <ccmywish@qq.com>
* Created on    : <2023-02-11>
* Last modified : <2023-04-20>
*
* ruby:
*
*   1. Cheat 'starship' to get version info
*   2. Get correct version info for rbenv commands
* -------------------------------------------------------------*/

import std.stdio;
import std.process   : environment;
import std.file      : getcwd;
import std.algorithm : canFind;

import rbenv.common;

// Written in the D programming language.
// --------------------------------------------------------------

string[] versionOptions = ["-v", "--version"];

int main(string[] args) {
    auto arg_len = args.length;

    VersionSetInfo vsi;
    vsi = get_current_version_with_setmsg();

    string pwd = getcwd();

    if ("" == vsi.ver) {
        // The last valid version to check is the global version, we've warned already
        // warn("rbenv: No valid version has been set");
        return -1;
    }

    // support starship to quickly get answer
    if(arg_len == 2 && versionOptions.canFind(args[1])) {
        writeln("ruby ", vsi.ver, " ", vsi.setmsg);
        return 0;
    } else {
        warn("rbenv: This is fake ruby.exe in $env:RBENV_ROOT\\rbenv\\bin");
        warn("rbenv: You shouldn't invoke 'ruby.exe', instead you should invoke 'ruby'");
        return 0;
    }

    return 0;
}
