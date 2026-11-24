/* --------------------------------------------------------------
* File          : common.d
* Authors       : Aoran Zeng <ccmywish@qq.com>
* Created on    : <2023-03-03>
* Last modified : <2026-11-24>
*
* common:
*
*   Common functions for 'fake ruby.exe' and
*                        'libexec\rbenv-exec.exe'
* -------------------------------------------------------------*/

module rbenv.common;

import std.stdio;
import std.process      : environment, executeShell;
import std.array        : split, join, array;
import std.algorithm    : canFind, startsWith, endsWith;
import std.algorithm    : filter, sort, map, cmp;
import std.file         : getcwd, chdir, dirEntries, SpanMode, exists, readText, read, write;
import std.path         : baseName, dirName, rootName;
import std.regex        : ctRegex, matchAll, matchFirst;
import std.string       : indexOf, splitLines, chompPrefix;

import core.stdc.stdlib : exit;

// Written in the D programming language.
// --------------------------------------------------------------


void warn(string str) {
    import std.format : format;
    auto colorized =  "\033[33m%s\033[0m".format(str); // yellow
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

private enum version_match_regexp = ctRegex!r"^(\d+)\.(\d+)\.(\d+)-(\d+)";

string RBENV_ROOT;
string SHIMS_DIR;
string GLOBAL_VERSION_FILE;

static this()
{
    RBENV_ROOT = environment["RBENV_ROOT"];
    SHIMS_DIR  = RBENV_ROOT ~ "\\shims";
    GLOBAL_VERSION_FILE = RBENV_ROOT ~ "\\global.txt";
}

string get_current_architecture() {
    // Prefer the OS architecture when running a 32-bit process under WOW64.
    string architecture;
    if ("PROCESSOR_ARCHITEW6432" in environment && environment["PROCESSOR_ARCHITEW6432"].length > 0) {
        architecture = environment["PROCESSOR_ARCHITEW6432"];
    } else if ("PROCESSOR_ARCHITECTURE" in environment) {
        architecture = environment["PROCESSOR_ARCHITECTURE"];
    }

    if (architecture == "ARM64" || architecture == "AARCH64") return "arm";
    if (architecture == "AMD64" || architecture == "X64" || architecture == "X86_64") return "x64";

    warn("rbenv: unsupported Windows architecture '" ~ architecture ~ "'");
    exit(1);
    return "";
}


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

    auto architecture = get_current_architecture();
    auto vers_file = RBENV_ROOT ~ "\\rbenv\\share\\versions-for-" ~ architecture ~ ".tsv";

    auto vers_str = readText(vers_file);
    auto vers_lines = vers_str.splitLines;
    string[] vers;

    foreach (line; vers_lines) {
        if (line.length == 0) continue;

        auto columns = line.split("\t");
        if (columns.length < 2 || columns[0] == "VERSION") continue;

        vers ~= columns[0];
    }

    return vers;
}


private int[4] parse_version_parts(string ver) {
    import std.conv : to;
    auto m = ver.matchFirst(version_match_regexp);
    if (m.empty) return [0, 0, 0, 0];
    return [m[1].to!int, m[2].to!int, m[3].to!int, m[4].to!int];
}

private bool version_gt(string a, string b) {
    if (a == b) return false;
    if (a == "head") return true;
    if (b == "head") return false;
    auto pa = parse_version_parts(a);
    auto pb = parse_version_parts(b);
    foreach (i; 0 .. 4) {
        if (pa[i] != pb[i]) return pa[i] > pb[i];
    }
    return a > b;
}

private bool match_version_prefix(string candidate, string ver) {
    if (ver.endsWith(".") || ver.endsWith("-")) {
        return candidate.startsWith(ver);
    }
    return candidate == ver || candidate.startsWith(ver ~ ".") || candidate.startsWith(ver ~ "-");
}

// Read all dir names in the RBENV_ROOT
string[] get_all_installed_versions() {

    // FilterResult!(__lambda1, _DirIterator!false)
    auto vers = dirEntries(RBENV_ROOT, SpanMode.shallow)
        .map!(dir => baseName(dir.name))
        .filter!(name => name.matchAll(version_match_regexp) || name == "head")
        .array;

    vers = vers.sort!((a, b) => version_gt(a, b)).array;

    string system_rb = environment.get("RBENV_SYSTEM_RUBY");

    if (system_rb != null) {
        vers ~= "system";
    }

    return vers;
}


string auto_fix_version_for_installed(string ver) {

    // `rvm --ruby-version use 3.1.2`
    //
    // rvm will generate 'ruby-3.1.2', but rbenv(shell) will only generate '3.1.2'
    // but rbenv(shell) will recognize 'ruby-3.1.2' too, so we do too
    if (ver.startsWith("ruby-")) {
        ver = ver.chompPrefix("ruby-");
    }

    auto versions = get_all_installed_versions();

    if (versions.canFind(ver)) {
        return ver;
    } else {
        foreach (s ; versions)  {
            if (match_version_prefix(s, ver)) { return s; }
        }
    }
    warn("rbenv: version " ~ ver ~ " not installed");

    // exit(0);
    // Now we don't exit instantly, but show the *informative version*,
    // to make starship/oh-my-posh user directly know what is wrong
    return ver ~ "NotInstalled";
}


string auto_fix_version_for_remote(string ver) {

    auto versions = get_all_remote_versions();

    if (versions.canFind(ver)) {
        return ver;
    } else {
        foreach (s ; versions)  {
            if (match_version_prefix(s, ver)) { return s; }
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
        where = RBENV_ROOT ~ "\\" ~ ver;
    }
    where ~= "\\bin";
    return where;
}


unittest {
    // no auto fix version
    auto path = get_ruby_bin_path_for_version("3.1.3-1");
    assert(path == "C:\\Ruby-on-Windows\\3.1.3-1\\bin" );
}


/**
Used for shim script to find the correct version of gem executable

Directly called by:

    rbenv-exec.exe shim-get-gem <arg>

Returns:

    'correct_ver_dir\gem_name.cmd' arguments or
    'correct_ver_dir\gem_name.bat' arguments
*/
string shim_get_gem(string cmd_path) {

    string cmd;

    // E.g. C:Ruby-on-Windows\shims\cr.bat
    // if (cmd_path.indexOf(':'))
    cmd = baseName(cmd_path, ".bat"); // Now 'cr'

    VersionSetInfo vsi = get_current_version_with_setmsg();
    auto ver = vsi.ver;

    // This condition is only met when global version is not set
    // Enforce users to set global version
    if (ver == "") {
        return "";
    }

    // Still need to call this function to do some work (e.g. find available bins)
    auto gem = get_gem_executable_by_version(cmd, ver);
    return gem;
}


// The argument 'name' is with no file type suffix!
string[] who_has_gem(string name) {

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


// Called by 'get_gem_executable_by_version()'
void gem_not_found(string name) {
    // NOTE! This line of output is specially designed to let batch shim eat off!
    // Because when gem not found, batch shim will still think the stdout's string
    // is the execution script path. However we really have nothing to feed the shim,
    // so give the shim a command like the sentense below, the shim will happily
    // recognize it and do nothing!
    stdout.writeln("Mr.rbenv's " ~ name ~ " batch shim, you should hide yourself");

    // These are the real output info for users to read
    stderr.writeln("rbenv: command '" ~ name ~ "' not found");

    // TODO: Fix it using template to match with list_who_has_gem()
    auto whos = who_has_gem(name);
    if (whos) {
        stderr.writeln("\nBut it exists in these Ruby versions:\n");
        auto whos_rows = whos.join("\n");
        stderr.writeln(whos_rows);
    }
}


// For 'rbenv whence' directly use
void list_who_has_gem(string name) {
    auto whos = who_has_gem(name);

    if (whos) {
        auto whos_rows = whos.join("\n");
        writeln(whos_rows);
    }
}


// Here, cmd is a Gem's executable name
string get_gem_executable_by_version (string cmd, string ver) {

    auto where = get_bin_path_for_version(ver);

    cmd = baseName(cmd, ".bat");
    cmd = baseName(cmd, ".cmd");

    // stderr.writeln("DEBUG: "~ cmd);

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
        where = RBENV_ROOT ~ "\\" ~ ver;
    }
    where ~= "\\bin";
    return where;
}


// --------------------------------------------------------------
//                          Version Get
// --------------------------------------------------------------


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

        // return "";
        // Now we don't return an empty string, but show the *informative version*,
        // to make starship/oh-my-posh user directly know what is wrong
        return "GlobalVersionNotSet";

    } else {
        return ver;
    }
}


// Read the .ruby-version file
LocalVersionInfo get_local_version() {

    LocalVersionInfo lvi;
    lvi.where = "";
    lvi.ver = "";

    auto cwd  = getcwd();
    auto cwd_saved = cwd;
    auto root = rootName(cwd);
    auto local_version_file = "";
    bool found = false;

    while (true) {
        if (root==cwd) break;
        local_version_file = cwd ~ "\\.ruby-version";
        if(local_version_file.exists) {
            found = true;
            break;
        };
        cwd = dirName(cwd);
        chdir(cwd);
    }

    if (found) {
        string ver_content = cast(string)read(local_version_file);
        // Just read the first line to resist some evil editors!!!
        string ver = splitLines(ver_content)[0];
        // Complete '3.1.3' with the suffix '-1'
        ver = auto_fix_version_for_installed(ver);
        lvi.where = local_version_file;
        lvi.ver = ver;
    }
    // writeln(cwd_saved);
    chdir(cwd_saved);
    return lvi;
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
