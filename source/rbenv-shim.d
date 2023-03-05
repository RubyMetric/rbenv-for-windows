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

// Auto import these global variables
//import rbenv.common : RBENV_ROOT, SHIMS_DIR, GLOBAL_VERSION_FILE;

int main(string[] args) {

    auto arg_len = args.length;
    // enforce(arg_len == 3);

    RBENV_ROOT = environment["RBENV_ROOT"];
    SHIMS_DIR  = RBENV_ROOT ~ "\\shims";

    if(args[1] == "get_gem_executable") {
        shim_get_gem_executable_location(args[2]).writeln;
        return 0;
    } else {
        stderr.writeln("Internal error");
        return -1;
    }
}
