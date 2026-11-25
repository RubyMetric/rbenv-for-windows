/* --------------------------------------------------------------
* console:
*
*   Colored messages for the user. A warning goes to stderr, a success
*   message goes to stdout.
* -------------------------------------------------------------*/

module rbenv.console;

import std.format : format;
import std.stdio  : stderr, writeln;

// Written in the D programming language.
// --------------------------------------------------------------


void warn(string str) {
    auto colorized =  "\033[33m%s\033[0m".format(str); // yellow
    // We use stderr exlicitly, so there's no incomplete output
    stderr.writeln(colorized);
}

void success(string str) {
    auto colorized =  "\033[32m%s\033[0m".format(str); // green
    writeln(colorized);
}
