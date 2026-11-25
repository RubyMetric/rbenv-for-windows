/* --------------------------------------------------------------
* remote_versions:
*
*   The Ruby versions that can be installed, read from the catalog
*   'share\versions-for-<architecture>.json' shipped with rbenv.
* -------------------------------------------------------------*/

module rbenv.remote_versions;

import std.algorithm : canFind, filter, map, sort;
import std.array     : array;
import std.conv      : to;
import std.file      : readText;
import std.json      : parseJSON;
import std.range     : back, empty, take;

import rbenv.errors;
import rbenv.host     : get_current_architecture;
import rbenv.paths    : RBENV_ROOT;
import rbenv.versions;

// Written in the D programming language.
// --------------------------------------------------------------


private enum RECENT_SERIES_COUNT = 10;


// Read versions list
string[] get_all_remote_versions() {

    auto architecture = get_current_architecture();
    auto vers_file = RBENV_ROOT ~ "\\rbenv\\share\\versions-for-" ~ architecture ~ ".json";

    auto vers_json = parseJSON(readText(vers_file));

    return vers_json.array.map!(entry => entry["version"].str).array;
}


// 'head' plus the newest version of each of the 10 newest minor series,
// e.g. 3.4.x, 3.3.x ... Used by 'rbenv install -l'
string[] get_recent_remote_versions() {
    auto remote_versions = get_all_remote_versions();
    foreach (name; remote_versions) {
        if (!is_valid_version_name(name)) {
            throw new RbenvError("Invalid remote version: " ~ name);
        }
    }

    auto versions = remote_versions.map!(to!Version).array;
    versions.sort!((left, right) => left > right);

    // The newest first, so the first one we meet of a series is its newest
    Version[] newest_of_each_series;
    foreach (ver; versions.filter!(ver => !ver.is_head)) {
        if (newest_of_each_series.empty || !ver.is_same_series_as(newest_of_each_series.back)) {
            newest_of_each_series ~= ver;
        }
    }

    string[] recent;
    if (versions.canFind!(ver => ver.is_head)) {
        recent ~= "head";
    }
    recent ~= newest_of_each_series.take(RECENT_SERIES_COUNT).map!(ver => ver.name).array;
    return recent;
}


// Returns null when the request matches no remote version
string find_remote_version(string requested_version) {
    return find_matching_version(get_all_remote_versions(), requested_version);
}


// rdmd -unittest -main .\remote_versions.d
unittest {
    auto arr  = get_all_remote_versions();
    auto ret2 = "2.7".find_remote_version;
    // writeln(ret2);
}
