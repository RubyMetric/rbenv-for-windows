import std.stdio;

GLOBAL_VERSION_FILE = environment['RBENV_ROOT'] ~ "\global.txt"

void main(string[] args) {
    string option = args[1];
    switch(option) {
        case "-v":
            writeln("ruby 4.1.2");
            break;
        default:
            // noop
    }
}


void warn(string str) {
    auto colorized =  "\033[33m%s\033[0m".format(str);  // UFCS
    writeln(colorized);
}


// Read the global.txt file
string get_global_version() {
    import std.file;

	if (! exists(GLOBAL_VERSION_FILE)) {
		return "rbenv: Global version file doesn't exist!";
	} else {
        // read return 'void[]'' type
        ver = cast(string)read(GLOBAL_VERSION_FILE)
	}

    if (!ver) warn("rbenv: No global version has been set, use rbenv global <version>")
    else {ver}
}


struct VersionInfo {
    string version;
    string setmsg;
}


VersionInfo get_current_version_with_setmsg() {

    VersionInfo vi;


    vi.version = ""

    return vi;
}
