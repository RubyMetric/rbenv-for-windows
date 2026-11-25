/* --------------------------------------------------------------
* File          : common.d
* Authors       : Aoran Zeng <ccmywish@qq.com>
* Created on    : <2023-03-03>
* Last modified : <2026-11-25>
*
* common:
*
*   Version detection returns facts: the version name, its source and path,
*   and its state. It does not turn an unavailable version into display text.
*   Shell takes precedence over local, then global.
*
*   get_current_versions() reports the configuration without creating a global
*   file. get_active_version() retains fake Ruby's global-file behavior.
*   Presentation and PowerShell responses belong to version_display.d and
*   version_protocol.d respectively. Other shared functions remain here.
* -------------------------------------------------------------*/

module rbenv.common;

import std.stdio;
import std.conv         : to;
import std.json         : JSONException, parseJSON;
import std.process      : environment, executeShell;
import std.array        : split, join, array;
import std.algorithm    : canFind, startsWith, endsWith;
import std.algorithm    : filter, sort, map, cmp;
import std.file         : getcwd, dirEntries, SpanMode, exists, isFile, readText, read, write;
import std.path         : baseName, buildPath, dirName, rootName;
import std.regex        : ctRegex, matchAll, matchFirst;
import std.string       : indexOf, splitLines, chompPrefix, strip, stripRight;
import std.uni          : toUpper;

import core.stdc.stdlib : exit;

// Written in the D programming language.
// --------------------------------------------------------------


void warn(string str) {
    import std.format : format;
    auto colorized =  "\033[33m%s\033[0m".format(str); // yellow
    // We use stderr exlicitly, so there's no incomplete output
    stderr.writeln(colorized);
}

void success(string str) {
    import std.format : format;
    auto colorized =  "\033[32m%s\033[0m".format(str); // green
    writeln(colorized);
}


// --------------------------------------------------------------
//                  Global variable and constant
// --------------------------------------------------------------

private enum version_match_regexp = ctRegex!r"^(\d+)\.(\d+)\.(\d+)-(\d+)";

string RBENV_ROOT;
string SHIMS_DIR;
string GLOBAL_VERSION_FILE;

static this()
{
    RBENV_ROOT = environment["RBENV_ROOT"];
    SHIMS_DIR  = RBENV_ROOT ~ "\\shims";
    GLOBAL_VERSION_FILE = RBENV_ROOT ~ "\\global.txt";
}

string get_current_architecture() {
    // Prefer the OS architecture when running a 32-bit process under WOW64.
    auto architecture = environment.get("PROCESSOR_ARCHITEW6432");
    if (!architecture.strip.length) {
        architecture = environment.get("PROCESSOR_ARCHITECTURE");
    }

    if (!architecture.strip.length) {
        warn("rbenv: unable to determine Windows architecture");
        exit(1);
    }

    architecture = architecture.toUpper;
    if (architecture == "ARM64" || architecture == "AARCH64") return "arm";
    if (architecture == "AMD64" || architecture == "X64" || architecture == "X86_64") return "x64";

    warn("rbenv: unsupported Windows architecture '" ~ architecture ~ "'");
    exit(1);
    return "";
}


// --------------------------------------------------------------
//                              Struct
// --------------------------------------------------------------
private struct Version {
    string name;
    int major;
    int minor;
    int patch;
    int revision;

    this(string name) {
        import std.exception : enforce;

        this.name = name;
        if (name == "head") return;

        auto parts = name.matchFirst(version_match_regexp);
        enforce(!parts.empty, "Invalid version: " ~ name);
        major = parts[1].to!int;
        minor = parts[2].to!int;
        patch = parts[3].to!int;
        revision = parts[4].to!int;
    }

    int opCmp(ref const Version other) const {
        if (name == "head") return other.name == "head" ? 0 : 1;
        if (other.name == "head") return -1;

        auto result = cmp(
            [major, minor, patch, revision],
            [other.major, other.minor, other.patch, other.revision]
        );
        return result != 0 ? result : cmp(name, other.name);
    }
}

enum VersionSource {
    none,
    shell,
    local,
    global
}

enum ActiveVersionState {
    available,
    notInstalled,
    globalNotSet
}

struct ActiveVersion {
    string name;
    VersionSource source;
    string source_path;
    ActiveVersionState state;
}

struct LocalVersion {
    string name; // Raw first line of .ruby-version
    string path; // Empty when no local file was found
}

struct SystemVersion {
    string name;
    string path;
}

struct CurrentVersions {
    ActiveVersion active;
    string        global;
    LocalVersion  local;
    string        shell;
    SystemVersion system;
}


// Read versions list
string[] get_all_remote_versions() {

    auto architecture = get_current_architecture();
    auto vers_file = RBENV_ROOT ~ "\\rbenv\\share\\versions-for-" ~ architecture ~ ".json";

    auto vers_json = parseJSON(readText(vers_file));
    string[] vers;

    foreach (entry; vers_json.array) {
        vers ~= entry["version"].str;
    }

    return vers;
}


string[] get_recent_remote_versions() {
    auto remote_versions = get_all_remote_versions();
    foreach (ver; remote_versions) {
        if (ver != "head" && ver.matchFirst(version_match_regexp).empty) {
            throw new JSONException("Invalid remote version: " ~ ver);
        }
    }

    auto versions = remote_versions.map!(to!Version).array;
    versions.sort!((left, right) => left > right);
    string[] recent;
    int previous_major;
    int previous_minor;
    size_t minor_count;
    bool has_head;

    foreach (ver; versions) {
        if (ver.name == "head") {
            if (!has_head) recent ~= ver.name;
            has_head = true;
            continue;
        }

        if (minor_count && ver.major == previous_major && ver.minor == previous_minor) continue;
        if (minor_count == 10) break;

        recent ~= ver.name;
        previous_major = ver.major;
        previous_minor = ver.minor;
        minor_count++;
    }
    return recent;
}

bool match_version_prefix(string candidate, string ver) {
    if (ver.endsWith(".") || ver.endsWith("-")) {
        return candidate.startsWith(ver);
    }
    return candidate == ver || candidate.startsWith(ver ~ ".") || candidate.startsWith(ver ~ "-");
}

// Read all dir names in the RBENV_ROOT
string[] get_all_installed_versions() {

    auto versions = dirEntries(RBENV_ROOT, SpanMode.shallow)
        .map!(dir => baseName(dir.name))
        .filter!(name => name.matchAll(version_match_regexp) || name == "head")
        .map!(to!Version)
        .array;

    versions.sort!((left, right) => left > right);
    auto version_names = versions.map!(ver => ver.name).array;

    string system_rb = environment.get("RBENV_SYSTEM_RUBY");

    if (system_rb.length) {
        version_names ~= "system";
    }

    return version_names;
}


string find_installed_version(string ver) {
    // `rvm --ruby-version use 3.1.2`
    //
    // rvm will generate 'ruby-3.1.2', but rbenv(shell) will only generate '3.1.2'
    // but rbenv(shell) will recognize 'ruby-3.1.2' too, so we do too
    if (ver.startsWith("ruby-")) {
        ver = ver.chompPrefix("ruby-");
    }

    auto versions = get_all_installed_versions();

    if (versions.canFind(ver)) {
        return ver;
    } else {
        foreach (s ; versions)  {
            if (match_version_prefix(s, ver)) { return s; }
        }
    }
    return null;
}


string[] get_system_ruby_version_and_path() {
    auto ver_and_path = environment["RBENV_SYSTEM_RUBY"].split("<=>");
    // Error: cannot cast expression `ver_and_path` of type `string[]` to `string[2]
    // return cast(string[2])ver_and_path;
    return ver_and_path;
}


// return the ruby bin path for specific version
string get_ruby_bin_path_for_version(string ver) {
    string where;
    if (ver == "system") {
        auto ver_and_path = get_system_ruby_version_and_path();
        where = ver_and_path[1];
    } else {
        where = RBENV_ROOT ~ "\\" ~ ver;
    }
    where ~= "\\bin";
    return where;
}


unittest {
    // no auto fix version
    auto path = get_ruby_bin_path_for_version("3.1.3-1");
    assert(path == "C:\\Ruby-on-Windows\\3.1.3-1\\bin" );
}


// The argument 'name' is with no file type suffix!
string[] who_has_gem(string name) {

    string[] versions = get_all_installed_versions();
    string[] whos;
    string   where;

    foreach (ver ; versions) {
        if (ver == "system") {
            where = get_system_ruby_version_and_path()[1];
            where = where ~ "\\bin";
        } else {
            where = RBENV_ROOT ~ "\\" ~ ver ~ "\\bin";
        }

        auto bat_file = where ~ "\\" ~ name ~ ".bat";
        auto cmd_file = where ~ "\\" ~ name ~ ".cmd";

        // '.bat' first, because from 2023, basically all gems are in '.bat'
        if      (bat_file.exists) { whos ~= bat_file; }
        else if (cmd_file.exists) { whos ~= cmd_file; }
        else    { continue; }
    }

    return whos;
}


// Called by 'get_gem_executable_by_version()'
void gem_not_found(string name) {
    // NOTE! This line of output is specially designed to let batch shim eat off!
    // Because when gem not found, batch shim will still think the stdout's string
    // is the execution script path. However we really have nothing to feed the shim,
    // so give the shim a command like the sentense below, the shim will happily
    // recognize it and do nothing!
    stdout.writeln("Mr.rbenv's " ~ name ~ " batch shim, you should hide yourself");

    // These are the real output info for users to read
    stderr.writeln("rbenv: command '" ~ name ~ "' not found");

    // TODO: Fix it using template to match with list_who_has_gem()
    auto whos = who_has_gem(name);
    if (whos) {
        stderr.writeln("\nBut it exists in these Ruby versions:\n");
        auto whos_rows = whos.join("\n");
        stderr.writeln(whos_rows);
    }
}


// For 'rbenv whence' directly use
void list_who_has_gem(string name) {
    auto whos = who_has_gem(name);

    if (whos) {
        auto whos_rows = whos.join("\n");
        writeln(whos_rows);
    }
}


// Here, cmd is a Gem's executable name
string get_gem_executable_by_version (string cmd, string ver) {

    auto where = get_bin_path_for_version(ver);

    cmd = baseName(cmd, ".bat");
    cmd = baseName(cmd, ".cmd");

    // stderr.writeln("DEBUG: "~ cmd);

    auto bat_file = where ~ "\\" ~ cmd ~ ".bat";
    auto cmd_file = where ~ "\\" ~ cmd ~ ".cmd";

    // '.bat' first, because from 2023, basically all gems are in '.bat'
    if      (bat_file.exists) { return bat_file; }
    else if (cmd_file.exists) { return cmd_file; }
    else {
        gem_not_found(cmd);
        exit(-1);
    }
}


// return the bin path for specific version
string get_bin_path_for_version(string ver) {
    string where;

    if (ver == "system") {
        where = get_system_ruby_version_and_path()[1];
    } else {
        where = RBENV_ROOT ~ "\\" ~ ver;
    }
    where ~= "\\bin";
    return where;
}


// --------------------------------------------------------------
//                          Version Get
// --------------------------------------------------------------

string get_global_version_for_active() {

	if (! exists(GLOBAL_VERSION_FILE)) {
        // warn("rbenv: Global version file doesn't exist!");
        // return "";
        write(GLOBAL_VERSION_FILE, []);
    }

    return get_configured_global_version();
}


// global.txt is written as ASCII and rbenv local writes UTF-8. Existing files
// may still contain UTF-8 with a BOM or UTF-16 from PowerShell or other tools.
// Detect the BOM and normalize the contents to UTF-8 before interpreting them.
private string read_version_file(string version_file) {
    import std.utf : toUTF8, UTFException, validate;

    auto bytes = cast(ubyte[]) read(version_file);

    // UTF-16 may be little-endian or big-endian; the BOM identifies the order.
    if (bytes.length >= 2 &&
        ((bytes[0] == 0xff && bytes[1] == 0xfe) ||
         (bytes[0] == 0xfe && bytes[1] == 0xff))) {

        if ((bytes.length - 2) % 2 != 0) {
            throw new UTFException("Invalid UTF-16 in " ~ version_file);
        }
        bool little_endian = bytes[0] == 0xff;
        wchar[] text;

        foreach (i; 0 .. (bytes.length - 2) / 2) {
            auto a = bytes[2 + i * 2];
            auto b = bytes[3 + i * 2];
            text ~= cast(wchar)(little_endian ? (a | (b << 8)) : ((a << 8) | b));
        }

        return toUTF8(text);
    }

    // Otherwise expect UTF-8, with or without a BOM.
    if (bytes.length >= 3 && bytes[0 .. 3] == [0xef, 0xbb, 0xbf]) {
        bytes = bytes[3 .. $];
    }

    auto text = cast(string) bytes;
    validate(text);
    return text;
}


string get_configured_global_version() {
    if (!GLOBAL_VERSION_FILE.exists || !GLOBAL_VERSION_FILE.isFile) {
        return "";
    }

    auto value = read_version_file(GLOBAL_VERSION_FILE);
    return value.strip.length ? value.stripRight("\r\n") : "";
}


LocalVersion get_local_version_in_directory(string directory) {
    LocalVersion local_version;
    auto version_file = buildPath(directory, ".ruby-version");

    if (version_file.exists && version_file.isFile) {
        local_version.path = version_file;
        auto lines = read_version_file(version_file).splitLines();
        if (lines.length) {
            local_version.name = lines[0];
        }
    }

    return local_version;
}


// Find the nearest local file without changing the process working directory.
LocalVersion get_nearest_local_version() {
    auto cwd  = getcwd();
    auto root = rootName(cwd);

    while (root != cwd) {
        auto local_version = get_local_version_in_directory(cwd);
        if (local_version.path.length) {
            return local_version;
        }

        auto parent = dirName(cwd);
        if (parent == cwd) {
            break;
        }
        cwd = parent;
    }

    return LocalVersion.init;
}


// Read the global shell variable
string get_shell_version() {
    // https://dlang.org/phobos/std_process.html#environment.get
    // get won't throw
    auto ver = environment.get("RBENV_VERSION");
    if (ver is null) return "";
    else return ver;
}


private ActiveVersion determine_active_version(
    string       shell_version,
    LocalVersion local_version = LocalVersion.init,
    string       global_version = ""
) {
    ActiveVersion active;

    if (shell_version.length) {
        active.name = shell_version;
        active.source = VersionSource.shell;
    } else if (local_version.path.length && local_version.name.strip.length) {
        active.name = find_installed_version(local_version.name);
        if (active.name is null) {
            active.name = local_version.name.chompPrefix("ruby-");
            active.state = ActiveVersionState.notInstalled;
        }
        active.source = VersionSource.local;
        active.source_path = local_version.path;
    } else if (global_version.length) {
        active.name = global_version;
        active.source = VersionSource.global;
        active.source_path = GLOBAL_VERSION_FILE;
    }

    return active;
}


ActiveVersion get_active_version() {
    auto shell_version = get_shell_version();
    if (shell_version.length) {
        return determine_active_version(shell_version);
    }

    auto local_version = get_nearest_local_version();
    if (local_version.path.length && local_version.name.strip.length) {
        return determine_active_version(shell_version, local_version);
    }

    auto global_version = get_global_version_for_active();
    if (!global_version.length) {
        ActiveVersion active;
        active.source = VersionSource.global;
        active.source_path = GLOBAL_VERSION_FILE;
        active.state = ActiveVersionState.globalNotSet;
        return active;
    }
    return determine_active_version(shell_version, local_version, global_version);
}


CurrentVersions get_current_versions() {
    CurrentVersions current;
    current.global = get_configured_global_version();
    current.local  = get_nearest_local_version();
    current.shell  = get_shell_version();

    auto system = environment.get("RBENV_SYSTEM_RUBY").split("<=>");
    if (system.length) {
        current.system.name = system[0];
    }
    if (system.length > 1) {
        current.system.path = system[1];
    }

    current.active = determine_active_version(current.shell, current.local, current.global);
    return current;
}
