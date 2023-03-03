/* --------------------------------------------------------------
* File          : rbenv.d
* Authors       : Aoran Zeng <ccmywish@qq.com>
* Created on    : <2023-03-03>
* Last modified : <2023-03-04>
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
import std.process : environment;
import std.array   : split, array;

enum version_match_regexp = r"\d{1,}\.\d{1,}\.\d{1,}-\d{1,}";

// Read versions list
string[] get_all_remote_versions() {

    import std.file : readText;

    auto vers_file = environment["RBENV_ROOT"] ~ "\\rbenv\\share\\versions.txt";

    auto vers_str = readText(vers_file);

    // split newline by default
    auto vers = vers_str.split;

    return vers;
}


// Read all dir names in the RBENV_ROOT
string[] get_all_installed_versions() {

    import std.file      : dirEntries, SpanMode;
    import std.algorithm : filter, sort, map, cmp;
    import std.regex     : matchAll;

    // FilterResult!(__lambda1, _DirIterator!false)
    auto vers = dirEntries(environment["RBENV_ROOT"], SpanMode.shallow).filter!(
        (dir) {
            auto name = dir.name;
            return name.matchAll(version_match_regexp) || name == "head" ;
        }
    ).map!(a => a.name).array;
    // https://dlang.org/phobos/std_algorithm_iteration.html#.map


    // https://dlang.org/phobos/std_algorithm_sorting.html#.sort
    // https://dlang.org/phobos/std_algorithm_comparison.html#.cmp
    vers = vers.sort!( (a,b) => cmp(a,b) == 1 ).array;

    string system_rb = environment.get("RBENV_SYSTEM_RUBY");

    if (system_rb != null) {
        vers ~= "system";
    }

    return vers;
}


int main() {
    auto arr = get_all_remote_versions();
    auto arr2 = get_all_installed_versions();
    writeln(arr2);
    return 0;
}
