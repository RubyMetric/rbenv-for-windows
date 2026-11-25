/* --------------------------------------------------------------
* current:
*
*   rbenv current: the configured versions as JSON. PowerShell parses it
*   and shows it to the user, so the JSON is a protocol with PowerShell,
*   not a message for the user. (Warnings still go to stderr.)
*
*   The JSON keeps the formatted active version and source for
*   compatibility, even though the underlying data is structured.
* -------------------------------------------------------------*/

module rbenv.commands.current;

import std.json  : JSONValue;
import std.stdio : writeln;

import rbenv.current_versions;
import rbenv.version_messages : format_active_version_name, format_active_version_source;
import rbenv.version_messages : warn_active_version;

// Written in the D programming language.
// --------------------------------------------------------------


void print_current_versions() {
    auto current = get_current_versions();
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
