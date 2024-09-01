/** ------------------------------------------------------------
 * File Name     : ruby.d
 * File Authors  : Aoran Zeng <ccmywish@qq.com>
 * Created On    : <2023-02-11>
 * Last Modified : <2024-09-02>
 *
 * ruby:
 *
 *  1. Cheat starship/oh-my-posh to get version info
 *  2. Get correct version info for rbenv commands
 *  3. Invoke the real ruby.exe
 * ------------------------------------------------------------*/

import std.stdio;
import std.process   : environment;
import std.file      : getcwd;
import std.algorithm : canFind;

import std.process : spawnShell, wait, Config;
import std.array;

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

    // When user only input '-v' or '--version'
    //      we suppress invocation of real ruby.exe
    // This supports starship/oh-my-posh to get answer more quickly
    if(arg_len == 2 && versionOptions.canFind(args[1])) {
        writeln("ruby ", vsi.ver, " ", vsi.setmsg);
        return 0;
    }

    string[] escape_args = [];
    foreach (arg; args) {
        if (arg.canFind(" ")) {
            escape_args ~= "\"" ~ arg ~ "\"";
        } else if (""==arg) {   // ruby -e ""
            escape_args ~= `""`;
        } else {
            escape_args ~= arg;
        }
    }

    string rubyexe = get_bin_path_for_version(vsi.ver) ~ "\\ruby.exe";

    string shellcmd = join(rubyexe ~ escape_args[1..$], " ");
    // writeln(shellcmd);

    auto pid = spawnShell(shellcmd,    // must be a string, rather than string array
                          null,        // env
                          Config.none, // config
                          pwd          // workDir
                          );

    return wait(pid);

    return 0;
}
