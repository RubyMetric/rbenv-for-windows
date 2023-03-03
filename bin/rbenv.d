/* --------------------------------------------------------------
* File          : rbenv.d
* Authors       : Aoran Zeng <ccmywish@qq.com>
* Created on    : <2023-03-03>
* Last modified : <2023-03-03>
*
* rbenv:
*
*   This D file works normally.
*
* ----------
* Changelog:
*
* ~> v0.1.0
* <2023-03-03> Create file
* -------------------------------------------------------------*/

module rbenv;

import std.stdio;

// Read versions list
string[] get_all_remote_versions() {

    import std.file    : readText;
    import std.array   : split;
    import std.process : environment;

    auto vers_file = environment["RBENV_ROOT"] ~ "\\rbenv\\share\\versions.txt";

    auto vers_str = readText(vers_file);

    // split newline by default
    auto vers = vers_str.split;

    return vers;
}


int main() {
    auto arr = get_all_remote_versions();
    writeln(arr);
    return 0;
}
