/* --------------------------------------------------------------
* version_protocol:
*
*   Write the version and architecture responses consumed by PowerShell.
*   Single values and lists use plain stdout; current uses JSON. Diagnostics
*   go to stderr so they cannot be mistaken for response data.
*
*   The current JSON keeps the existing formatted active version and source
*   fields for compatibility, even though the underlying data is structured.
*   User-facing command output is handled separately by rbenv-exec.
* -------------------------------------------------------------*/

module rbenv.version_protocol;

import std.json : JSONValue;
import std.stdio : stderr, writeln;

import rbenv.common;
import rbenv.version_display : format_active_version_name, format_active_version_source;
import rbenv.version_display : warn_active_version;


int write_installed_version(string requested_version) {
    auto installed_version = find_installed_version(requested_version);
    if (installed_version is null) {
        stderr.writeln("rbenv: version " ~ requested_version ~ " not installed");
        return 1;
    }

    writeln(installed_version);
    return 0;
}


void write_installed_versions() {
    foreach (installed_version; get_all_installed_versions()) {
        writeln(installed_version);
    }
}


void write_current_architecture() {
    writeln(get_current_architecture());
}


void write_current_versions(CurrentVersions current) {
    warn_active_version(current.active);
    JSONValue active = JSONValue([
        "version": format_active_version_name(current.active),
        "source":  format_active_version_source(current.active)
    ]);
    JSONValue local = JSONValue([
        "version": current.local.name,
        "path":    current.local.path
    ]);
    JSONValue system = JSONValue([
        "version": current.system.name,
        "path":    current.system.path
    ]);

    JSONValue result = JSONValue([
        "active": active,
        "global": JSONValue(current.global),
        "local":  local,
        "shell":  JSONValue(current.shell),
        "system": system
    ]);

    writeln(result.toString());
}
