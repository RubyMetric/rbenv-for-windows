/* --------------------------------------------------------------
* host:
*
*   Facts about the Windows machine rbenv runs on: its CPU architecture
*   and its system Ruby (a RubyInstaller that was not installed by rbenv).
* -------------------------------------------------------------*/

module rbenv.host;

import std.array   : split;
import std.process : environment;
import std.string  : strip;
import std.uni     : toUpper;

import rbenv.errors;

// Written in the D programming language.
// --------------------------------------------------------------


string get_current_architecture() {
    // Prefer the OS architecture when running a 32-bit process under WOW64.
    auto architecture = environment.get("PROCESSOR_ARCHITEW6432");
    if (!architecture.strip.length) {
        architecture = environment.get("PROCESSOR_ARCHITECTURE");
    }

    if (!architecture.strip.length) {
        throw new RbenvError("unable to determine Windows architecture");
    }

    architecture = architecture.toUpper;
    if (architecture == "ARM64" || architecture == "AARCH64") return "arm";
    if (architecture == "AMD64" || architecture == "X64" || architecture == "X86_64") return "x64";

    throw new RbenvError("unsupported Windows architecture '" ~ architecture ~ "'");
}


// Error: cannot cast expression `ver_and_path` of type `string[]` to `string[2]
//      return cast(string[2])ver_and_path;
//
// That is why the version and the path are kept in a struct, not in a string[2]
struct SystemVersion {
    string name;
    string path;
}


bool has_system_ruby() {
    return environment.get("RBENV_SYSTEM_RUBY").length > 0;
}


// bin\rbenv.ps1 can only put a string into $env:RBENV_SYSTEM_RUBY, so it joins
// the version and the path with '<=>', e.g.
//
//   3.1.2-1<=>C:\Ruby31-x64
//
SystemVersion get_system_version() {
    SystemVersion system;

    auto fields = environment.get("RBENV_SYSTEM_RUBY").split("<=>");
    if (fields.length > 0) {
        system.name = fields[0];
    }
    if (fields.length > 1) {
        system.path = fields[1];
    }

    return system;
}
