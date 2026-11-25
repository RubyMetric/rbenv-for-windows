/* --------------------------------------------------------------
* active_version:
*
*   Decide which Ruby version is in effect: shell takes precedence over
*   local, which takes precedence over global.
*
*   The result is facts: the version name, where it came from, and its
*   state. It never turns an unavailable version into text such as
*   'xxxNotInstalled'; presenting it is the job of version_messages.d.
*
*   get_active_version() is for the fake ruby.exe and the shims. It
*   creates global.txt when missing and reports a missing global version
*   as a state. current_versions.d reports the configuration without
*   creating any file.
* -------------------------------------------------------------*/

module rbenv.active_version;

import std.process : environment;
import std.string  : strip;

import rbenv.installed_versions : find_installed_version;
import rbenv.paths              : GLOBAL_VERSION_FILE;
import rbenv.version_files;
import rbenv.versions           : remove_ruby_prefix;

// Written in the D programming language.
// --------------------------------------------------------------


enum VersionSource {
    none,
    shell,
    local,
    global
}


enum ActiveVersionState {
    available,
    not_installed,
    global_not_set
}


struct ActiveVersion {
    string name;
    VersionSource source;
    string source_path;
    ActiveVersionState state;
}


// Read the global shell variable
string get_shell_version() {
    // https://dlang.org/phobos/std_process.html#environment.get
    // get won't throw
    auto ver = environment.get("RBENV_VERSION");
    if (ver is null) return "";
    else return ver;
}


// The local and global versions are 'lazy': a source is only read when no
// source before it has decided the version.
//
// When no source sets a version, the result has no name and no source.
ActiveVersion determine_active_version(
         string       shell_version,
    lazy LocalVersion local_version,
    lazy string       global_version
) {
    ActiveVersion active;

    if (shell_version.length) {
        active.name   = shell_version;
        active.source = VersionSource.shell;
        return active;
    }

    auto local = local_version;
    if (local.path.length && local.name.strip.length) {
        // Complete '3.1.3' with the suffix '-1'
        active.name = find_installed_version(local.name);
        if (active.name is null) {
            active.name  = remove_ruby_prefix(local.name);
            active.state = ActiveVersionState.not_installed;
        }
        active.source      = VersionSource.local;
        active.source_path = local.path;
        return active;
    }

    auto global = global_version;
    if (global.length) {
        active.name        = global;
        active.source      = VersionSource.global;
        active.source_path = GLOBAL_VERSION_FILE;
    }

    return active;
}


private string get_global_version_creating_file() {
    ensure_global_version_file();
    return get_configured_global_version();
}


ActiveVersion get_active_version() {
    auto active = determine_active_version(
        get_shell_version(),
        get_nearest_local_version(),
        get_global_version_creating_file()
    );

    if (active.source == VersionSource.none) {
        active.source      = VersionSource.global;
        active.source_path = GLOBAL_VERSION_FILE;
        active.state       = ActiveVersionState.global_not_set;
    }

    return active;
}
