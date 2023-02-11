/* --------------------------------------------------------------
* File          : ruby.d
* Authors       : ccmywish <ccmywish@qq.com>
* Created on    : <2023-02-11>
* Last modified : <2023-02-11>
* Contributors  :
*
* ruby:
*
*   Cheat starship
*
* ----------
* Changelog:
*
* ~> v0.1.0
* <2023-02-11> Create file
* -------------------------------------------------------------*/

import std.stdio;

string global_version_file_path() {
    import std.process : environment;
    return environment["RBENV_ROOT"] ~ "\\global.txt";
}

void main(string[] args) {

    auto arg_len = args.length;

    if(arg_len < 2) return;

    string option = args[1];    // bound check here

    VersionInfo vi;

    switch(option) {
        case "-v":
            vi = get_current_version_with_setmsg();
            if ("" != vi.ver){
                writeln("ruby ", vi.ver);
            } else {
                // https://dlang.org/phobos/std_process.html#spawnProcess
                import std.process : spawnProcess, wait;
                wait(spawnProcess(["ruby", "-v"]));
            }
            break;
        default:
            // noop
    }
}


void warn(string str) {
    import std.format : format;
    auto colorized =  "\033[33m%s\033[0m".format(str); // UFCS
    writeln(colorized);
}


// Read the global.txt file
string get_global_version() {
    import std.file;
    string global_version_file = global_version_file_path();

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
    import std.process : executeShell;
    auto ret = executeShell("git rev-parse --show-toplevel");
    if (ret.status != 0) return lvi;

    auto git_root = ret.output;
    string local_version_file =  git_root ~ "\\.ruby-version";

    import std.file;
    if (exists(local_version_file)) {
        string ver = cast(string)read(local_version_file);
        // Complete '3.1.3' with the suffix '-1'
        // ver = auto_fix_version_for_installed($ver)
        lvi.where = local_version_file;
        lvi.ver = ver;
        return lvi;
    } else {
        return lvi;
    }
}


// Read the global shell variable
string get_this_shell_version() {
    import std.process : environment;
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
        vi.setmsg = "(set by " ~ global_version_file_path() ~ ")";
        return vi;
    }

    // return empty string, this may lead to find the system ruby
    return vi;
}
