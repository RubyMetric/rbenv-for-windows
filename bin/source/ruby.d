/* --------------------------------------------------------------
* File          : ruby.d
* Authors       : Aoran Zeng <ccmywish@qq.com>
* Created on    : <2023-02-11>
* Last modified : <2023-03-04>
*
* ruby:
*
*   1. Cheat 'starship' to get version info
*   2. Get correct version info for rbenv commands
*
* ----------
* Changelog:
*
* ~> v0.1.1
* <2023-03-04> Auto fix for local version
* <2023-03-03>
#   1. Improve 'ruby -v' info to coordinate with rbenv
#   2. Don't delegate to real ruby.exe anymore
#
* <2023-02-14> Make 'global_version_file' global variable
*
* ~> v0.1.0
* <2023-02-11> Create file
* -------------------------------------------------------------*/

import std.stdio;
import std.process : environment, executeShell;

import rbenv;

// Written in the D programming language.
// --------------------------------------------------------------

string global_version_file;


int main(string[] args) {
    auto arg_len = args.length;

    global_version_file = environment["RBENV_ROOT"] ~ "\\global.txt";

    VersionInfo vi;
    vi = get_current_version_with_setmsg();

    import std.file : getcwd;
    string pwd = getcwd();

    if ("" == vi.ver) {
        warn("rbenv: No valid version has been set");
        return -1;
    }

    // support starship to quickly get answer
    if(arg_len == 2 && args[1] == "-v") {
        writeln("ruby ", vi.ver, " ", vi.setmsg);
        return 0;
    } else {
        warn("rbenv: This is fake ruby.exe in $env:RBENV_ROOT\\rbenv\\bin");
        warn("rbenv: You shouldn't invoke 'ruby.exe', instead you should invoke 'ruby'");
        return 0;
    }

    return 0;
}


// Read the global.txt file
string get_global_version() {
    import std.file;

	if (! exists(global_version_file)) return "rbenv: Global version file doesn't exist!";

    // read return 'void[]'' type
    string ver = cast(string)read(global_version_file);

    if ("" == ver) {
        warn("rbenv: No global version has been set, use rbenv global <version>");
        return "";
    } else {
        return ver;
    }
}


struct LocalVersionInfo{
    string where;
    string ver;
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


struct VersionInfo {
    string ver;
    string setmsg;
}

VersionInfo get_current_version_with_setmsg() {

    VersionInfo vi;

    string ver = get_this_shell_version();
    if("" != ver) {
        vi.ver = ver;
        vi.setmsg = "(set by $env:RBENV_VERSION environment variable)";
        return vi;
    }


    LocalVersionInfo lvi;
    lvi = get_local_version();

    if("" != lvi.ver) {
        vi.ver = lvi.ver;
        vi.setmsg = "(set by " ~ lvi.where ~ ")";
        return vi;
    }

    ver = get_global_version();
    if("" != ver) {
        vi.ver = ver;
        vi.setmsg = "(set by " ~ global_version_file ~ ")";
        return vi;
    }

    // return empty string, this will cause program to exit -1
    return vi;
}
