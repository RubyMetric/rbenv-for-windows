/* --------------------------------------------------------------
* powershell_helpers:
*
*   Auxiliary commands that PowerShell functions call to get an answer
*   from D. Their names in rbenv-exec are surrounded by underscores.
*
*   Single values and lists are printed to stdout, one per line, and
*   PowerShell reads them. Diagnostics go to stderr, so they cannot be
*   mistaken for the answer.
* -------------------------------------------------------------*/

module rbenv.commands.powershell_helpers;

import std.stdio : writeln;

import rbenv.host               : get_current_architecture;
import rbenv.installed_versions : get_all_installed_versions, require_installed_version;

// Written in the D programming language.
// --------------------------------------------------------------


void print_installed_version(string requested_version) {
    writeln(require_installed_version(requested_version));
}


void print_installed_versions() {
    foreach (installed_version; get_all_installed_versions()) {
        writeln(installed_version);
    }
}


void print_current_architecture() {
    writeln(get_current_architecture());
}
