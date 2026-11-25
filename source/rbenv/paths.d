/* --------------------------------------------------------------
* paths:
*
*   Where things live inside RBENV_ROOT.
* -------------------------------------------------------------*/

module rbenv.paths;

import std.process : environment;

import rbenv.host : get_system_version;

// Written in the D programming language.
// --------------------------------------------------------------


string RBENV_ROOT;
string SHIMS_DIR;
string GLOBAL_VERSION_FILE;

static this()
{
    RBENV_ROOT = environment["RBENV_ROOT"];
    SHIMS_DIR  = RBENV_ROOT ~ "\\shims";
    GLOBAL_VERSION_FILE = RBENV_ROOT ~ "\\global.txt";
}


// return the bin path for specific version
string get_bin_path_for_version(string ver) {
    string where;

    if (ver == "system") {
        where = get_system_version().path;
    } else {
        where = RBENV_ROOT ~ "\\" ~ ver;
    }
    where ~= "\\bin";
    return where;
}


unittest {
    // no auto fix version
    auto path = get_bin_path_for_version("3.1.3-1");
    assert(path == "C:\\Ruby-on-Windows\\3.1.3-1\\bin" );
}
