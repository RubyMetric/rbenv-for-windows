/* --------------------------------------------------------------
* install_list:
*
*   rbenv install -l: list the recent versions that can be installed.
* -------------------------------------------------------------*/

module rbenv.commands.install_list;

import std.stdio : writeln;

import rbenv.remote_versions : get_recent_remote_versions;

// Written in the D programming language.
// --------------------------------------------------------------


void list_recent_versions() {
    foreach (ver; get_recent_remote_versions()) {
        writeln(ver);
    }
}
