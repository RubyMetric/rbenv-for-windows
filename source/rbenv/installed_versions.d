/* --------------------------------------------------------------
* installed_versions:
*
*   The Ruby versions installed under RBENV_ROOT, plus the system Ruby.
* -------------------------------------------------------------*/

module rbenv.installed_versions;

import std.algorithm : filter, map, sort;
import std.array     : array;
import std.conv      : to;
import std.file      : dirEntries, SpanMode;
import std.path      : baseName;

import rbenv.errors;
import rbenv.host     : has_system_ruby;
import rbenv.paths    : RBENV_ROOT;
import rbenv.versions;

// Written in the D programming language.
// --------------------------------------------------------------


// Read all dir names in the RBENV_ROOT
string[] get_all_installed_versions() {

    // FilterResult!(__lambda1, _DirIterator!false)
    auto versions = dirEntries(RBENV_ROOT, SpanMode.shallow)
        .map!(dir => baseName(dir.name))
        .filter!(is_valid_version_name)
        .map!(to!Version)
        .array;

    versions.sort!((left, right) => left > right);
    auto version_names = versions.map!(ver => ver.name).array;

    if (has_system_ruby()) {
        version_names ~= "system";
    }

    return version_names;
}


// Returns null when the request matches no installed version
string find_installed_version(string requested_version) {
    return find_matching_version(
        get_all_installed_versions(),
        remove_ruby_prefix(requested_version)
    );
}


// Like find_installed_version, but a missing version is an error
string require_installed_version(string requested_version) {
    auto installed_version = find_installed_version(requested_version);
    if (installed_version is null) {
        throw new RbenvError("version " ~ requested_version ~ " not installed");
    }
    return installed_version;
}


// rdmd -unittest -main .\installed_versions.d
unittest {
    auto arr2 = get_all_installed_versions();
    auto ret  = "2.7".find_installed_version;
}
