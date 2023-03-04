/* --------------------------------------------------------------
* File          : rbenv.d
* Authors       : Aoran Zeng <ccmywish@qq.com>
* Created on    : <2023-03-03>
* Last modified : <2023-03-04>
*
* rbenv:
*
*   Common functions for 'fake ruby.exe' and
*                        'libexec\rbenv-rehash.exe'
*
* ----------
* Changelog:
*
* ~> v0.1.0
* <2023-03-03> Create file
* -------------------------------------------------------------*/

module rbenv.common;

import std.stdio;
import std.process      : environment;
import std.array        : split, array;
import std.algorithm    : canFind, startsWith;
import std.algorithm    : filter, sort, map, cmp;
import std.file         : dirEntries, SpanMode;
import std.path         : baseName;
import std.regex        : matchAll;
import core.stdc.stdlib : exit;

// Written in the D programming language.
// --------------------------------------------------------------

void warn(string str) {
    import std.format : format;
    auto colorized =  "\033[33m%s\033[0m".format(str); // UFCS yellow
    writeln(colorized);
}

void success(string str) {
    import std.format : format;
    auto colorized =  "\033[32m%s\033[0m".format(str); // green
    writeln(colorized);
}


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

    // FilterResult!(__lambda1, _DirIterator!false)
    auto vers = dirEntries(environment["RBENV_ROOT"], SpanMode.shallow).filter!(
        (dir) {
            auto name = dir.name;
            return name.matchAll(version_match_regexp) || name == "head" ;
        }
    ).map!(a => baseName(a.name)).array;
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


string auto_fix_version_for_installed(string ver) {

    auto versions = get_all_installed_versions();

    if (versions.canFind(ver)) {
        return ver;
    } else {
        foreach (s ; versions)  {
            // writeln(s);
            auto yes = s.startsWith(ver);
            if (yes) { return s; }
        }
    }
    warn("rbenv: version " ~ ver ~ " not installed");
    exit(0);
}


string auto_fix_version_for_remote(string ver) {

    auto versions = get_all_remote_versions();

    if (versions.canFind(ver)) {
        return ver;
    } else {
        foreach (s ; versions)  {
            auto yes = s.startsWith(ver);
            if (yes) { return s; }
        }
    }

    warn("rbenv: version " ~ ver ~ " not installed");
    exit(0);
}


// rdmd -unittest -main .\rbenv.d
unittest {
    auto arr  = get_all_remote_versions();
    auto arr2 = get_all_installed_versions();
    auto ret  = "2.7".auto_fix_version_for_installed;
    auto ret2 = "2.7".auto_fix_version_for_remote;
    // writeln(ret2);
}



string[] get_system_ruby_version_and_path() {
    auto ver_and_path = environment["RBENV_SYSTEM_RUBY"].split("<=>");
    // Error: cannot cast expression `ver_and_path` of type `string[]` to `string[2]
    // return cast(string[2])ver_and_path;
    return ver_and_path;
}


// return the ruby bin path for specific version
string get_ruby_bin_path_for_version(string ver) {
    string where;
    if (ver == "system") {
        auto ver_and_path = get_system_ruby_version_and_path();
        where = ver_and_path[1];
    } else {
        where = environment.get("RBENV_ROOT") ~ "\\" ~ ver;
    }
    where ~= "\\bin";
    return where;
}


unittest {
    // no auto fix version
    auto path = get_ruby_bin_path_for_version("3.1.3-1");
    assert(path == "C:\\Ruby-on-Windows\\3.1.3-1\\bin" );
}
