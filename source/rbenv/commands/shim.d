/* --------------------------------------------------------------
* shim:
*
*   The side of rbenv-exec that the shims talk to. A shim is a .bat file
*   in SHIMS_DIR (see rehash.d), it runs
*
*       rbenv-exec.exe shim-get-gem <arg>
*
*   and executes whatever that prints to stdout. So here stdout is a
*   protocol with the shim, not a message for the user.
* -------------------------------------------------------------*/

module rbenv.commands.shim;

import std.array  : join;
import std.path   : baseName;
import std.stdio  : writeln;

import rbenv.active_version;
import rbenv.errors;
import rbenv.gem_executables : find_gem_executable_by_version, who_has_gem;
import rbenv.version_messages : format_active_version_name, warn_active_version;

// Written in the D programming language.
// --------------------------------------------------------------


// Called by 'shim_get_gem()'
void gem_not_found(string name) {
    // NOTE! This line of output is specially designed to let batch shim eat off!
    // Because when gem not found, batch shim will still think the stdout's string
    // is the execution script path. However we really have nothing to feed the shim,
    // so give the shim a command like the sentense below, the shim will happily
    // recognize it and do nothing!
    writeln("Mr.rbenv's " ~ name ~ " batch shim, you should hide yourself");

    // These are the real output info for users to read
    auto message = "command '" ~ name ~ "' not found";

    // TODO: Fix it using template to match with list_who_has_gem()
    auto whos = who_has_gem(name);
    if (whos) {
        message ~= "\n\nBut it exists in these Ruby versions:\n\n";
        message ~= whos.join("\n");
    }

    throw new RbenvError(message, -1);
}


/**
Used for shim script to find the correct version of gem executable

Directly called by:

    rbenv-exec.exe shim-get-gem <arg>

Returns:

    'correct_ver_dir\gem_name.cmd' arguments or
    'correct_ver_dir\gem_name.bat' arguments
*/
string shim_get_gem(string cmd_path) {

    string cmd;

    // E.g. C:Ruby-on-Windows\shims\cr.bat
    // if (cmd_path.indexOf(':'))
    cmd = baseName(cmd_path, ".bat"); // Now 'cr'

    ActiveVersion active = get_active_version();
    warn_active_version(active);
    auto ver = format_active_version_name(active);

    // This condition is only met when global version is not set
    // Enforce users to set global version
    if (ver == "") {
        return "";
    }

    // Still need to call this function to do some work (e.g. find available bins)
    auto gem = find_gem_executable_by_version(cmd, ver);
    if (gem is null) {
        gem_not_found(cmd);
    }
    return gem;
}
