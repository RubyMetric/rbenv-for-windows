/* --------------------------------------------------------------
* File          : rbenv-exec.d
* Authors       : Aoran Zeng <ccmywish@qq.com>
* Created on    : <2023-03-04>
* Last modified : <2026-11-25>
*
* rbenv-exec:
*
*   rbenv-exec.exe rehash-gem     <gem_name>
*   rbenv-exec.exe rehash-version <version>
*   rbenv-exec.exe shim-get-gem   <gem_shim.bat>
*   rbenv-exec.exe list-who-has   <gem_name>
*   rbenv-exec.exe _find-installed-version_ <version>
*   rbenv-exec.exe _get-all-installed-versions_
*   rbenv-exec.exe _get-current-architecture_
*   rbenv-exec.exe list-recent-versions
*   rbenv-exec.exe get-global-version
*   rbenv-exec.exe set-global-version <version>
*   rbenv-exec.exe get-local-version
*   rbenv-exec.exe set-local-version <version>
*   rbenv-exec.exe current
*
*   This file only picks the command and reports its failure. The commands
*   themselves live in rbenv\commands\, one module per feature, and the
*   facts they work with (versions, paths ...) live in rbenv\.
*
*   Names surrounded by underscores identify auxiliary commands, which
*   PowerShell functions call to get an answer; they are not meant for users.
*
*   A command reports an expected failure by throwing RbenvError, see
*   rbenv\errors.d. It is printed as 'rbenv: <message>'.
*
* -------------------------------------------------------------*/

// module `rbenv-exec` has non-identifier characters in filename, use module declaration instead
module rbenv.exec;

import std.algorithm : all, find;
import std.file      : FileException;
import std.json      : JSONException;
import std.range     : empty, front;
import std.stdio     : stderr, writeln;
import std.string    : stripRight;
import std.utf       : UTFException;

import rbenv.commands.current           : print_current_versions;
import rbenv.commands.global_version    : get_global_version, set_global_version;
import rbenv.commands.install_list      : list_recent_versions;
import rbenv.commands.local_version     : get_local_version, set_local_version;
import rbenv.commands.powershell_helpers;
import rbenv.commands.rehash            : rehash_single_gem_echo, rehash_version;
import rbenv.commands.shim              : shim_get_gem;
import rbenv.commands.whence            : list_who_has_gem;
import rbenv.errors;

// Written in the D programming language.
// --------------------------------------------------------------


alias CommandHandler = void function(string[] arguments);

struct Command {
    string         name;
    string         usage;           // The arguments it takes, shown when they are wrong
    size_t         min_arguments;
    size_t         max_arguments;
    CommandHandler run;

    bool accepts(string[] arguments) const {
        bool count_is_right = arguments.length >= min_arguments && arguments.length <= max_arguments;
        return count_is_right && arguments.all!(argument => argument.length > 0);
    }

    string usage_message() const {
        return ("Usage: rbenv-exec.exe " ~ name ~ " " ~ usage).stripRight;
    }
}


private immutable Command[] COMMANDS = [
    Command("rehash-gem",     "<gem_name> [for <gem>]", 1, 3, (arguments) => rehash_gem(arguments)),
    Command("rehash-version", "<version>",              1, 1, (arguments) => rehash_version(arguments[0])),
    Command("shim-get-gem",   "<gem_shim.bat>",         1, 1, (arguments) => writeln(shim_get_gem(arguments[0]))),
    Command("list-who-has",   "<gem_name>",             1, 1, (arguments) => list_who_has_gem(arguments[0])),

    Command("_find-installed-version_",   "<version>", 1, 1, (arguments) => print_installed_version(arguments[0])),
    Command("_get-all-installed-versions_",   "",      0, 0, (arguments) => print_installed_versions()),
    Command("_get-current-architecture_",     "",      0, 0, (arguments) => print_current_architecture()),

    Command("list-recent-versions", "", 0, 0, (arguments) => list_recent_versions()),

    Command("get-global-version", "",          0, 0, (arguments) => get_global_version()),
    Command("set-global-version", "<version>", 1, 1, (arguments) => set_global_version(arguments[0])),
    Command("get-local-version",  "",          0, 0, (arguments) => get_local_version()),
    Command("set-local-version",  "<version>", 1, 1, (arguments) => set_local_version(arguments[0])),

    Command("current", "", 0, 0, (arguments) => print_current_versions()),
];


int main(string[] args) {
    try {
        return run_command(args);
    } catch (RbenvError error) {
        return report_failure(error.msg, error.exit_code);
    } catch (FileException error) {
        return report_failure(error.msg);
    } catch (UTFException error) {
        return report_failure(error.msg);
    } catch (JSONException error) {
        return report_failure(error.msg);
    }
}


private int report_failure(string message, int exit_code = 1) {
    stderr.writeln("rbenv: " ~ message);
    return exit_code;
}


int run_command(string[] args) {
    // auto arg_len = args.length;
    // enforce(arg_len == 3);

    if (args.length < 2) {
        stderr.writeln("rbenv-exec.exe: missing command");
        return -1;
    }

    auto matched = COMMANDS.find!(command => command.name == args[1]);
    if (matched.empty) {
        stderr.writeln("rbenv-exec.exe: Unmatched command " ~ args[1]);
        return -1;
    }

    auto command   = matched.front;
    auto arguments = args[2 .. $];
    if (!command.accepts(arguments)) {
        stderr.writeln(command.usage_message);
        return 1;
    }

    command.run(arguments);
    return 0;
}


private void rehash_gem(string[] arguments) {
    // Full form:
    //
    //    $ rbenv rehash rougify for rouge
    //
    // This is for rubygems_plugin.rb to work
    if (arguments.length >= 3) {
        rehash_single_gem_echo(arguments[0], arguments[2]);
    } else {
    // Reduced form:
    //
    //    $ rbenv rehash rougify
    //
    // This is for user to invoke when sometimes necessary
        rehash_single_gem_echo(arguments[0]);
    }
}
