/* --------------------------------------------------------------
* File          : rbenv-exec.d
* Authors       : Aoran Zeng <ccmywish@qq.com>
* Created on    : <2023-03-04>
* Last modified : <2023-03-05>
*
* rbenv-exec:
*
*   rbenv-exec.exe rehash-gem     <gem_name>
*   rbenv-exec.exe rehash-version <version>
*   rbenv-exec.exe shim-get-gem   <gem_shim.bat>
*
* -------------------------------------------------------------*/

// module `rbenv-exec` has non-identifier characters in filename, use module declaration instead
module rbenv.exec;

import std.stdio;
import std.process      : environment;
import std.array        : array;
import std.algorithm    : remove, endsWith;
import std.algorithm    : map, filter;
import std.file         : dirEntries, SpanMode;
import std.file         : write; // override std.stdio : write
import std.path         : baseName;
import std.exception    : enforce;

import rbenv.common;

// Written in the D programming language.
// --------------------------------------------------------------


enum REHASH_TEMPLATE =
`:: Auto generated by 'rbenv rehash'
@ECHO OFF
SET find_gem="%~dp0..\rbenv\libexec\rbenv-exec.exe shim-get-gem %~0"
FOR /F "delims=" %%i IN ('%find_gem%') DO SET gem_exe=%%i
%gem_exe% %*
`;
/*
if exists, %gem_exe% is
   C:\Ruby-on-Windows\correct_version_dir\bin\'gem_name'.bat
or
   C:\Ruby-on-Windows\correct_version_dir\bin\'gem_name'.cmd
*/


int main(string[] args) {

    auto arg_len = args.length;
    // enforce(arg_len == 3);

    // !!!
    // We must define all three, to make rbenv\common.d work
    RBENV_ROOT = environment["RBENV_ROOT"];
    SHIMS_DIR  = RBENV_ROOT ~ "\\shims";
    GLOBAL_VERSION_FILE = RBENV_ROOT ~ "\\global.txt";

    if(args[1] == "rehash-gem") {
        rehash_single_gem_echo(args[2]);
        return 0;
    }
    else if (args[1] == "rehash-version") {
        rehash_version(args[2]);
        return 0;
    }
    else if (args[1] == "shim-get-gem") {
        shim_get_gem(args[2]).writeln;
        return 0;
    }
    else {
        stderr.writeln("rbenv-exec.exe: Internal error");
        return -1;
    }
}


void rehash_single_gem(string name) {
    string file = SHIMS_DIR ~ "\\" ~ name ~ ".bat";
    // std.file : write NOT std.stdio : write
    write(file, REHASH_TEMPLATE);
}


/*
Generate shims for specific name across all versions

Note that $name shouldn't have suffix

This is called after you install a gem
*/
void rehash_single_gem_echo(string name) {
    rehash_single_gem(name);
    success("rbenv: Rehash gem " ~ "'" ~ name ~ "'");
}


/*
Generate shims for a version

We need shims dir to always have the names that every Ruby has installed

How can we achieve this? Via two steps:
    1. Every time you install a new Ruby version, call 'rehash_version'
    2. Every time you install a gem, call 'rehash_single_gem'
*/
void rehash_version (string arg_ver) {

    auto ver = auto_fix_version_for_installed(arg_ver);

    auto where = get_ruby_bin_path_for_version(ver);

    auto bats = dirEntries(where, SpanMode.shallow).map!(
        entry => baseName(entry.name)
    ).filter!(
        f => f.endsWith(".bat")
    ).array;

    // From Ruby 3.1.0-1, all default gems except 'gem.cmd' are xxx.bat
    // So we still should handle cmds before 3.1.0-1 and for 'gem.cmd'
    auto cmds = dirEntries(where, SpanMode.shallow).map!(
        entry => baseName(entry.name)
    ).filter!(
        f => f.endsWith(".cmd")
    ).array;

    // 'setrbvars.cmd' and 'ridk.cmd' shouldn't be rehashed
    cmds.remove!("a == \"setrbvars.cmd\"");
    cmds.remove!("a == \"ridk.cmd\"");


    // remove .bat suffix
    bats = bats.map!(f => baseName(f, ".bat")).array;
    // remove .cmd suffix ;
    cmds = cmds.map!(f => baseName(f, ".cmd")).array;

    auto gems = bats ~ cmds;

    // writeln(gems);

    foreach (exe ; gems) {
        rehash_single_gem(exe);
    }

    import std.conv : to;
    success("rbenv: Rehash all " ~ gems.length.to!(string) ~ " gems in '" ~ ver ~ "'");
}