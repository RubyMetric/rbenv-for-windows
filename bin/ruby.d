/* --------------------------------------------------------------
* File          : ruby.d
* Authors       : ccmywish <ccmywish@qq.com>
* Created on    : <2023-02-11>
* Last modified : <2023-03-03>
* Contributors  :
*
* ruby:
*
*   Cheat starship
*
* ----------
* Changelog:
*
* ~> v0.1.1
* <2023-03-03>
#   1. Improve 'ruby -v' info
#   2. Don't delegate when '-v' using system ruby
#
* <2023-02-14> Make 'global_version_file' global variable
*
* ~> v0.1.0
* <2023-02-11> Create file
* -------------------------------------------------------------*/

import std.stdio;

string global_version_file;


int main(string[] args) {
    auto arg_len = args.length;

    import std.process : environment;
    global_version_file = environment["RBENV_ROOT"] ~ "\\global.txt";

    VersionInfo vi;
    vi = get_current_version_with_setmsg();

    import std.file : getcwd;
    string pwd = getcwd();

    if ("" == vi.ver) {
        return delegate_to_real_ruby_from_cmd(pwd, args[1..$] );
    }

    // We don't delegate here, to support starship to quickly get answer
    if(arg_len == 2 && args[1] == "-v") {
        writeln("ruby ", vi.ver, " ", vi.setmsg, `
rbenv: Use 'ruby --version' for real version info`);
        return 0;
    }
    return delegate_to_real_ruby_from_rbenv(pwd, vi.setmsg, vi.ver, args[1..$]);
}


int delegate_to_real_ruby_from_rbenv(string pwd, string setmsg, string ver, string[] args) {
    import std.process : spawnProcess, wait, environment, Config;
    import std.string : indexOf, startsWith;
    import std.file : chdir, dirEntries , SpanMode ;
    import std.algorithm;
    import std.array : array;

    string root =  environment["RBENV_ROOT"];
    if (setmsg.indexOf(".ruby-version")) {

        // Switch directories first, so we directly get basenames
        chdir(root);
        // foreach(f; dirEntries("", SpanMode.shallow) ){writeln(f);}

        // std.algorithm.iteration.FilterResult! -> sd.file.DirEntry[]
        auto dirs = dirEntries("", SpanMode.shallow).filter!(
            d => d.name.startsWith(ver)).array;

        ver = dirs[0];
    }

    string ruby_exe = root ~ "\\" ~ ver ~ "\\bin\\ruby.exe" ;

    auto pid = spawnProcess([ruby_exe] ~ args[0..$],
                            null,        // env
                            Config.none, // config
                            pwd);        // workDir
    return wait(pid);
}


// Call the real ruby.exe
int delegate_to_real_ruby_from_cmd(string pwd, string[] args) {
    import std.process : spawnShell, wait, Config;
    import std.array;

    /*
    https://dlang.org/phobos/std_process.html#.spawnProcess
    On Windows, spawnProcess will search for the executable in the following sequence:

    [
      As you can see, this fake ruby.exe is always here (the first) to search ...
      So we can't delgetage to real ruby.exe, what a pity.
    ]
    1. The directory from which the application loaded. [This is where the fake ruby.exe exists in]

    2. The current directory for the parent process.    [This is the PWD]
    3. The 32-bit Windows system directory.
    4. The 16-bit Windows system directory.
    5. The Windows directory.
    6. The directories listed in the PATH environment variable.
    */


    /* So the strategy here fails

    import std.algorithm : find;
    auto path = environment.get("PATH");
    // \rbenv\bin;C:\Ruby-on-Windows\shims\bin;......
    auto path_rm_rbenv_bin = find(path, "\\rbenv\\bin;");
    path_rm_rbenv_bin = find(path_rm_rbenv_bin, ";");

    writeln(path_rm_rbenv_bin);
    environment.remove("PATH");
    environment["PATH"] = path_rm_rbenv_bin;
    string[string] new_env = ["PATH" : path_rm_rbenv_bin ];
    auto pid = spawnProcess(["ruby.exe"] ~ args[0..$]  ,new_env, Config.newEnv);
    */


    // https://dlang.org/phobos/std_process.html#.spawnShell
    auto shellcmd = join(["ruby.exe"] ~ args[0..$], " ");
    // Haha, now we bypass PowerShell, directly run CMD
    //   Because path env var 'rbenv\bin' is added from PowerShell,
    //   so we skip this fake ruby.exe sucessfully
    auto pid = spawnShell(shellcmd,
                          null,        // env
                          Config.none, // config
                          pwd          // workDir
                          );
    return wait(pid);
}


void warn(string str) {
    import std.format : format;
    auto colorized =  "\033[33m%s\033[0m".format(str); // UFCS
    writeln(colorized);
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
    import std.process : executeShell;
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
        vi.setmsg = "(set by " ~ global_version_file ~ ")";
        return vi;
    }

    // return empty string, this may lead to find the system ruby
    return vi;
}
