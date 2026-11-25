/* --------------------------------------------------------------
* version_files:
*
*   Read the files that configure a Ruby version: global.txt and the
*   .ruby-version files of local projects.
*
*   Reading only reports what the files say. Whether the version they name
*   is installed is decided elsewhere.
* -------------------------------------------------------------*/

module rbenv.version_files;

import std.algorithm : startsWith;
import std.file      : exists, getcwd, isFile, read, write;
import std.path      : buildPath, dirName, rootName;
import std.string    : splitLines, strip, stripRight;
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
//                          .ruby-version
// --------------------------------------------------------------

struct LocalVersion {
    string name; // Raw first line of .ruby-version
    string path; // Empty when no local file was found
}


// Read the .ruby-version file
LocalVersion get_local_version_in_directory(string directory) {
    LocalVersion local_version;
    auto version_file = buildPath(directory, ".ruby-version");

    if (version_file.exists && version_file.isFile) {
        local_version.path = version_file;
        auto lines = read_version_file(version_file).splitLines();
        if (lines.length) {
            // Just read the first line to resist some evil editors!!!
            local_version.name = lines[0];
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
