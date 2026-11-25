/* --------------------------------------------------------------
* global:
*
*   rbenv global: show or set the global version, stored in global.txt.
*
*   Setting it writes global.txt before rehashing, so a rehash failure is
*   reported even though the version has already been saved.
* -------------------------------------------------------------*/

module rbenv.commands.global;

import std.algorithm : all;
import std.file      : exists, isFile, write;
import std.stdio     : writeln;

import rbenv.commands.rehash    : rehash_version;
import rbenv.console            : success;
import rbenv.errors;
import rbenv.installed_versions : require_installed_version;
import rbenv.paths              : GLOBAL_VERSION_FILE;
import rbenv.version_files      : get_configured_global_version;

// Written in the D programming language.
// --------------------------------------------------------------


void get_global_version() {
    if (GLOBAL_VERSION_FILE.exists && !GLOBAL_VERSION_FILE.isFile) {
        throw new RbenvError("global version file is not a file: " ~ GLOBAL_VERSION_FILE);
    }

    auto global_version = get_configured_global_version();
    if (!global_version.length) {
        writeln("rbenv: No global version has been set, use rbenv global <version>");
    } else {
        writeln(global_version);
    }
}


void set_global_version(string requested_version) {
    auto installed_version = require_installed_version(requested_version);

    // global.txt is written as ASCII, see doc\PowerShell-problems.md
    if (!installed_version.all!(character => character <= 0x7f)) {
        throw new RbenvError("global version must contain only ASCII characters");
    }

    write(GLOBAL_VERSION_FILE, installed_version);
    success("rbenv: Change to global version '" ~ installed_version ~ "'");

    // <2023-05-05> Although I've fixed the bug of bundler process to successfully trigger
    // the post-install hook in the share/rubygems_plugins.rb
    // And then, `rbenv rehash` after a `rbenv global` is no longer needed.
    //
    // But I think it now can be a second safeguard to ensure all gems' executables
    // are there in the shims dir. So I keep this statement.
    rehash_version(installed_version);
}
