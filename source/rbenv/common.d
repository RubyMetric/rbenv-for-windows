/* --------------------------------------------------------------
* File          : common.d
* Authors       : Aoran Zeng <ccmywish@qq.com>
* Created on    : <2023-03-03>
* Last modified : <2023-03-05>
*
* common:
*
*   Common functions for 'fake ruby.exe' and
*                        'libexec\rbenv-rehash.exe'
*                        'libexec\rbenv-shim.exe'
*
* ----------
* Changelog:
*
* <2023-03-03> Create file
* -------------------------------------------------------------*/

module rbenv.common;

import std.stdio;
import std.process      : environment, executeShell;
import std.array        : split, array;
import std.algorithm    : canFind, startsWith;
import std.algorithm    : filter, sort, map, cmp;
import std.file         : dirEntries, SpanMode, exists, readText, read;
import std.path         : baseName;
import std.regex        : matchAll;
import std.string       : indexOf;
import std.array        : join;

import core.stdc.stdlib : exit;

// Written in the D programming language.
// --------------------------------------------------------------

void warn(string str) {
    import std.format : format;
    auto colorized =  "\033[33m%s\033[0m".format(str); // UFCS yellow
    // We use stderr exlicitly, so there's no incomplete output
    stderr.writeln(colorized);
}

void success(string str) {
    import std.format : format;
    auto colorized =  "\033[32m%s\033[0m".format(str); // green
    writeln(colorized);
}


// --------------------------------------------------------------
//                  Global variable and constant
// --------------------------------------------------------------

enum version_match_regexp = r"\d{1,}\.\d{1,}\.\d{1,}-\d{1,}";

string RBENV_ROOT;
string SHIMS_DIR;
string GLOBAL_VERSION_FILE;

// --------------------------------------------------------------
//                              Struct
// --------------------------------------------------------------
struct VersionSetInfo {
    string ver;
    string setmsg;
}

struct LocalVersionInfo{
    string ver;
    string where;
}


// Read versions list
string[] get_all_remote_versions() {

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



/*
# Function:
#   used for shim script to find the correct version of gem executable
#
#     'correct_ver_dir\gem_name.cmd' arguments or
#     'correct_ver_dir\gem_name.bat' arguments
*/
string shim_get_gem_executable_location (string cmd_path) {

    string cmd;

    if (cmd_path.indexOf(':')) {
        // E.g. C:Ruby-on-Windows\shims\cr.bat
        cmd = baseName(cmd_path, ".bat"); // Now 'cr'
    }

    VersionSetInfo vsi = get_current_version_with_setmsg();
    auto ver = vsi.ver;

    // This condition is only met when global version is not set
    // Enforce users to set global version
    if (ver == "") {
        return "";
    }

    // Still need to call this function to do some work (e.g. find available bins)
    auto gem = get_gem_bin_location_by_version(cmd, ver);
    return gem;
}


// For:
//   1. 'rbenv whence' directly use
//   2. get_gem_bin_location_by_version()
string[] list_who_has (string name) {

    string[] versions = get_all_installed_versions();
    string[] whos;
    string   where;

    foreach (ver ; versions) {
        if (ver == "system") {
            where = get_system_ruby_version_and_path()[1];
            where = where ~ "\\bin";
        } else {
            where = RBENV_ROOT ~ "\\" ~ ver ~ "\\bin";
        }

        auto bat_file = where ~ "\\" ~ name ~ ".bat";
        auto cmd_file = where ~ "\\" ~ name ~ ".cmd";

        // '.bat' first, because from 2023, basically all gems are in '.bat'
        if      (bat_file.exists) { whos ~= bat_file; }
        else if (cmd_file.exists) { whos ~= cmd_file; }
        else    { continue; }
    }

    return whos;
}



// This is called by
//   1. 'get_gem_bin_location_by_version'
//   2. 'shim_get_gem_name'
//
void gem_not_found(string gem) {
    writeln("rbenv: command '" ~ gem ~ "' not found");

    auto whos = list_who_has(gem);

    if (whos) {
        writeln("\nBut it exists in these Ruby versions:\n");
        auto whos_rows = whos.join("\n");
        writeln(whos_rows);
    }
}



// Here, cmd is a Gem's executable name
string get_gem_bin_location_by_version (string cmd, string ver) {

    auto where = get_bin_path_for_version(ver);

    cmd = baseName(cmd, ".bat");
    cmd = baseName(cmd, ".cmd");

    auto bat_file = where ~ "\\" ~ cmd ~ ".bat";
    auto cmd_file = where ~ "\\" ~ cmd ~ ".cmd";

    // '.bat' first, because from 2023, basically all gems are in '.bat'
    if      (bat_file.exists) { return bat_file; }
    else if (cmd_file.exists) { return cmd_file; }
    else {
        gem_not_found(cmd);
        exit(-1);
    }
}



// return the bin path for specific version
string get_bin_path_for_version(string ver) {
    string where;

    if (ver == "system") {
        where = get_system_ruby_version_and_path()[1];
    } else {
        where = "$env:RBENV_ROOT\\" ~ ver;
    }
    where ~= "\\bin";
    return where;
}






// Read the global.txt file
string get_global_version() {

	if (! exists(GLOBAL_VERSION_FILE)) {
        // warn("rbenv: Global version file doesn't exist!");
        // return "";
        write(GLOBAL_VERSION_FILE, []);
    }

    // read return 'void[]'' type
    string ver = cast(string)read(GLOBAL_VERSION_FILE);

    if ("" == ver) {
        warn("rbenv: No global version has been set, use rbenv global <version>");
        return "";
    } else {
        return ver;
    }
}


// Read the .ruby-version file
LocalVersionInfo get_local_version() {

    LocalVersionInfo lvi;
    lvi.where = "";
    lvi.ver = "";

    // pwd = std.path.absolute();
    auto ret = executeShell("git rev-parse --show-toplevel");
    if (ret.status != 0) return lvi;

    auto git_root = ret.output;

    import std.string : strip;
    // Because git return '/' separated path, we also add "/.ruby-version"
    string local_version_file =  strip(git_root) ~ "/.ruby-version";

    import std.file;
    if (exists(local_version_file)) {
        string ver = cast(string)read(local_version_file);
        // Complete '3.1.3' with the suffix '-1'
        ver = auto_fix_version_for_installed(ver);
        lvi.where = local_version_file;
        lvi.ver = ver;
        return lvi;
    } else {
        return lvi;
    }
}


// Read the global shell variable
string get_this_shell_version() {
    // https://dlang.org/phobos/std_process.html#environment.get
    // get won't throw
    auto ver = environment.get("RBENV_VERSION");
    if (ver is null) return "";
    else return ver;
}


VersionSetInfo get_current_version_with_setmsg() {

    VersionSetInfo vsi;

    string ver = get_this_shell_version();
    if("" != ver) {
        vsi.ver = ver;
        vsi.setmsg = "(set by $env:RBENV_VERSION environment variable)";
        return vsi;
    }


    LocalVersionInfo lvi;
    lvi = get_local_version();

    if("" != lvi.ver) {
        vsi.ver = lvi.ver;
        vsi.setmsg = "(set by " ~ lvi.where ~ ")";
        return vsi;
    }

    ver = get_global_version();
    if("" != ver) {
        vsi.ver = ver;
        vsi.setmsg = "(set by " ~ GLOBAL_VERSION_FILE ~ ")";
        return vsi;
    }

    // return empty string, this will cause program to exit -1
    return vsi;
}
