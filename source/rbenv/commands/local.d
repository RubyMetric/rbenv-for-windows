/* --------------------------------------------------------------
* local:
*
*   rbenv local: show or set the local version of the current directory,
*   stored in its .ruby-version file.
*
*   Unlike 'rbenv current', showing it does not search parent directories.
* -------------------------------------------------------------*/

module rbenv.commands.local;

import std.array  : split;
import std.file   : getcwd, write;
import std.path   : buildPath;
import std.stdio  : writeln;
import std.string : strip;

import rbenv.errors;
import rbenv.installed_versions : require_installed_version;
import rbenv.version_files      : get_local_version_in_directory;

// Written in the D programming language.
// --------------------------------------------------------------


void get_local_version() {
    auto local_version = get_local_version_in_directory(getcwd());
    if (!local_version.path.length) {
        writeln("rbenv: no local version configured for this directory");
        return;
    }
    if (!local_version.name.strip.length) {
        throw new RbenvError("empty local version file: " ~ local_version.path);
    }

    writeln(require_installed_version(local_version.name));
}


void set_local_version(string requested_version) {
    auto installed_version = require_installed_version(requested_version);

    /**
     * To make every Ruby project portable from Windows to POSIX, we try to be
     * compatible with `rbenv`. So, we drop the RubyInstaller suffix.
     * e.g.
     *      remove the version '3.2.0-1' suffix '-1'
     */
    auto portable_version = installed_version.split("-")[0];
    auto version_file = buildPath(getcwd(), ".ruby-version");
    write(version_file, portable_version);
}
