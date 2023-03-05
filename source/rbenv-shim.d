/* --------------------------------------------------------------
* File          : rbenv-shim.d
* Authors       : Aoran Zeng <ccmywish@qq.com>
* Created on    : <2023-03-05>
* Last modified : <2023-03-05>
* Contributors  :
*
* rbenv-shim:
*
*   This D file works normally.
*
* ----------
* Changelog:
*
* ~> v0.1.0
* <2023-03-05> Create file
* -------------------------------------------------------------*/

module rbenv.shim;

import std.stdio;
import std.process      : environment;

import rbenv.common;

// Written in the D programming language.
// --------------------------------------------------------------


int main(string[] args) {

    auto arg_len = args.length;
    enforce(arg_len == 3);

    SHIMS_DIR = environment["RBENV_ROOT"] ~ "\\shims";

    if(args[1] == "get_gem_executable") {
        rehash_single_gem_echo(args[2]);
        return 0;
    } else {
        stderr.writeln("Internal error");
        return -1;
    }
}
