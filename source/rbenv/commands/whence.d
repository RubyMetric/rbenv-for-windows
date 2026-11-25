/* --------------------------------------------------------------
* whence:
*
*   rbenv whence: list the Ruby versions that have a given executable.
* -------------------------------------------------------------*/

module rbenv.commands.whence;

import std.stdio : writeln;

import rbenv.gem_executables : who_has_gem;

// Written in the D programming language.
// --------------------------------------------------------------


// For 'rbenv whence' directly use
void list_who_has_gem(string name) {
    foreach (executable; who_has_gem(name)) {
        writeln(executable);
    }
}
