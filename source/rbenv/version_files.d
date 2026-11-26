/* --------------------------------------------------------------
* version_files:
*
*   Read the files that configure a Ruby version: global.txt and the
*   .ruby-version, mise.toml or .tool-versions files of local projects.
*
*   Reading only reports what the files say. Whether the version they name
*   is installed is decided elsewhere.
* -------------------------------------------------------------*/

module rbenv.version_files;

import std.algorithm : startsWith;
import std.file      : exists, getcwd, isFile, read, write;
import std.path      : buildPath, dirName, rootName;
import std.regex     : matchFirst;
import std.string    : indexOf, split, splitLines, strip, stripRight;
import std.utf       : toUTF8, UTFException, validate;

import rbenv.paths : GLOBAL_VERSION_FILE;

// Written in the D programming language.
// --------------------------------------------------------------


private enum ubyte[] UTF8_BOM = [0xef, 0xbb, 0xbf];


private bool has_utf16_bom(const ubyte[] bytes) {
    return bytes.length >= 2 &&
        ((bytes[0] == 0xff && bytes[1] == 0xfe) ||   // little-endian
         (bytes[0] == 0xfe && bytes[1] == 0xff));    // big-endian
}


private string decode_utf16(const ubyte[] bytes, string version_file) {
    // UTF-16 may be little-endian or big-endian; the BOM identifies the order.
    bool little_endian = bytes[0] == 0xff;
    auto payload = bytes[2 .. $];   // skip the BOM

    if (payload.length % 2 != 0) {
        throw new UTFException("Invalid UTF-16 in " ~ version_file);
    }

    wchar[] text;
    foreach (i; 0 .. payload.length / 2) {
        auto first  = payload[i * 2];
        auto second = payload[i * 2 + 1];
        text ~= cast(wchar)(little_endian ? (first | (second << 8)) : ((first << 8) | second));
    }
    return toUTF8(text);
}


private string decode_utf8(ubyte[] bytes) {
    // Otherwise expect UTF-8, with or without a BOM.
    if (bytes.startsWith(UTF8_BOM)) {
        bytes = bytes[UTF8_BOM.length .. $];
    }

    auto text = cast(string) bytes;
    validate(text);
    return text;
}


// global.txt is written as ASCII and rbenv local writes UTF-8. Existing files
// may still contain UTF-8 with a BOM or UTF-16 from PowerShell or other tools.
// Detect the BOM and normalize the contents to UTF-8 before interpreting them.
//
// See doc\PowerShell-problems.md
private string read_version_file(string version_file) {
    // read return 'void[]'' type
    auto bytes = cast(ubyte[]) read(version_file);

    if (has_utf16_bom(bytes)) {
        return decode_utf16(bytes, version_file);
    }
    return decode_utf8(bytes);
}


// --------------------------------------------------------------
//                          global.txt
// --------------------------------------------------------------

void ensure_global_version_file() {

	if (! exists(GLOBAL_VERSION_FILE)) {
        // warn("rbenv: Global version file doesn't exist!");
        // return "";
        write(GLOBAL_VERSION_FILE, []);
    }
}


// Read the global.txt file
//
// Returns an empty string when no global version has been set
string get_configured_global_version() {
    if (!GLOBAL_VERSION_FILE.exists || !GLOBAL_VERSION_FILE.isFile) {
        return "";
    }

    auto value = read_version_file(GLOBAL_VERSION_FILE);
    return value.strip.length ? value.stripRight("\r\n") : "";
}


// --------------------------------------------------------------
//          .ruby-version, mise.toml and .tool-versions
// --------------------------------------------------------------

struct LocalVersion {
    string name; // Raw version from .ruby-version, or the ruby entry of mise.toml or .tool-versions
    string path; // Empty when no local file was found
}


// Read the 'ruby' entry of an asdf-style .tool-versions file, e.g. 'ruby 3.2.1'
// Returns an empty string when there is no ruby entry
private string parse_tool_versions_ruby(string contents) {
    foreach (line; contents.splitLines()) {
        auto content = line.strip;
        if (content.length == 0 || content.startsWith("#")) {
            continue;
        }

        // Only the first version of the ruby entry is used
        auto tokens = content.split();
        if (tokens.length >= 2 && tokens[0] == "ruby") {
            return tokens[1];
        }
    }
    return "";
}


// Read the ruby entry of the [tools] table of a mise.toml file. Supports
// 'ruby = "3.3.0"', 'ruby = ["3.3.0", ...]' and 'ruby = { version = "3.3.0" }'.
// Returns an empty string when there is no ruby entry
private string parse_mise_toml_ruby(string contents) {
    bool in_tools = false;
    foreach (line; contents.splitLines()) {
        auto content = line.strip;
        if (content.length == 0 || content.startsWith("#")) {
            continue;
        }

        if (content.startsWith("[")) {
            in_tools = content == "[tools]";
            continue;
        }

        auto equal = content.indexOf('=');
        if (!in_tools || equal < 0 || content[0 .. equal].strip != "ruby") {
            continue;
        }

        auto value = content[equal + 1 .. $].strip;
        auto match = value.startsWith("{")
            ? matchFirst(value, `version\s*=\s*['"]([^'"]+)['"]`)
            : matchFirst(value, `['"]([^'"]+)['"]`);
        if (!match.empty) {
            return match[1];
        }
    }
    return "";
}


// Read the .ruby-version file, falling back to the mise.toml and then the
// .tool-versions file. A mise.toml or .tool-versions without a ruby entry is ignored.
LocalVersion get_local_version_in_directory(string directory) {
    LocalVersion local_version;

    auto ruby_version_file = buildPath(directory, ".ruby-version");
    if (ruby_version_file.exists && ruby_version_file.isFile) {
        local_version.path = ruby_version_file;
        auto lines = read_version_file(ruby_version_file).splitLines();
        if (lines.length) {
            // Just read the first line to resist some evil editors!!!
            local_version.name = lines[0];
        }
        return local_version;
    }

    auto mise_file = buildPath(directory, "mise.toml");
    if (mise_file.exists && mise_file.isFile) {
        auto name = parse_mise_toml_ruby(read_version_file(mise_file));
        if (name.length) {
            local_version.path = mise_file;
            local_version.name = name;
            return local_version;
        }
    }

    auto tool_versions_file = buildPath(directory, ".tool-versions");
    if (tool_versions_file.exists && tool_versions_file.isFile) {
        auto name = parse_tool_versions_ruby(read_version_file(tool_versions_file));
        if (name.length) {
            local_version.path = tool_versions_file;
            local_version.name = name;
        }
    }

    return local_version;
}


// Find the nearest local file without changing the process working directory.
LocalVersion get_nearest_local_version() {
    auto directory = getcwd();
    auto root      = rootName(directory);

    while (root != directory) {
        auto local_version = get_local_version_in_directory(directory);
        if (local_version.path.length) {
            return local_version;
        }

        auto parent = dirName(directory);
        if (parent == directory) {
            break;
        }
        directory = parent;
    }

    return LocalVersion.init;
}


unittest {
    // Comments and other tools are skipped; the first ruby entry wins
    assert(parse_tool_versions_ruby("# managed\nnodejs 20.1.0\nruby 3.2.1\n") == "3.2.1");
    assert(parse_tool_versions_ruby("ruby   3.3.0-1  3.2.1\n") == "3.3.0-1");
    assert(parse_tool_versions_ruby("nodejs 20.1.0\n") == "");
    assert(parse_tool_versions_ruby("# ruby 3.2.1\n") == "");
}


unittest {
    assert(parse_mise_toml_ruby("[tools]\nnodejs = \"20\"\nruby = \"3.3.0\"\n") == "3.3.0");
    assert(parse_mise_toml_ruby("[tools]\nruby = ['3.2.2', '3.1']\n") == "3.2.2");
    assert(parse_mise_toml_ruby("[tools]\nruby = { version = \"3.4.1\", compile = false }\n") == "3.4.1");
    // ruby outside [tools] is not a tool version
    assert(parse_mise_toml_ruby("[env]\nruby = \"3.0.0\"\n") == "");
    assert(parse_mise_toml_ruby("[tools]\nnodejs = \"20\"\n") == "");
}
