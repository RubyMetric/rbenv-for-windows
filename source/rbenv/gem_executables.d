/* --------------------------------------------------------------
* gem_executables:
*
*   Find the executable of a Gem, e.g. 'rake', inside the bin directory
*   of a Ruby version. A Gem executable is a .bat or a .cmd file.
* -------------------------------------------------------------*/

module rbenv.gem_executables;

import std.file : exists;
import std.path : baseName;

import rbenv.installed_versions : get_all_installed_versions;
import rbenv.paths              : get_bin_path_for_version;

// Written in the D programming language.
// --------------------------------------------------------------


// Returns null when there is no such executable in the bin directory
private string find_gem_executable_in(string bin_dir, string name) {
    auto bat_file = bin_dir ~ "\\" ~ name ~ ".bat";
    auto cmd_file = bin_dir ~ "\\" ~ name ~ ".cmd";

    // '.bat' first, because from 2023, basically all gems are in '.bat'
    if      (bat_file.exists) { return bat_file; }
    else if (cmd_file.exists) { return cmd_file; }
    else    { return null; }
}


// The argument 'name' is with no file type suffix!
string[] who_has_gem(string name) {

    string[] whos;

    foreach (ver ; get_all_installed_versions()) {
        auto executable = find_gem_executable_in(get_bin_path_for_version(ver), name);

        if (executable !is null) { whos ~= executable; }
    }

    return whos;
}


// Here, cmd is a Gem's executable name
//
// Returns null when this Ruby version has no such executable
string find_gem_executable_by_version (string cmd, string ver) {

    auto where = get_bin_path_for_version(ver);

    cmd = baseName(cmd, ".bat");
    cmd = baseName(cmd, ".cmd");

    // stderr.writeln("DEBUG: "~ cmd);

    return find_gem_executable_in(where, cmd);
}
