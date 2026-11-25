/* --------------------------------------------------------------
* versions:
*
*   What a version name is, how versions are ordered, and how a request
*   such as '3.2' is matched against a list of version names.
*
*   A version name is either 'head' or a RubyInstaller version like
*   '3.2.1-1'. 'head' is newer than everything else.
* -------------------------------------------------------------*/

module rbenv.versions;

import std.algorithm : canFind, cmp, endsWith, startsWith;
import std.conv      : to;
import std.regex     : ctRegex, matchFirst;
import std.string    : chompPrefix;

import rbenv.errors;

// Written in the D programming language.
// --------------------------------------------------------------


private enum version_match_regexp = ctRegex!r"^(\d+)\.(\d+)\.(\d+)-(\d+)";


bool is_valid_version_name(string name) {
    return name == "head" || !name.matchFirst(version_match_regexp).empty;
}


struct Version {
    string name;
    int major;
    int minor;
    int patch;
    int revision;

    this(string name) {
        this.name = name;
        if (is_head) return;

        auto parts = name.matchFirst(version_match_regexp);
        if (parts.empty) {
            throw new RbenvError("Invalid version: " ~ name);
        }
        major    = parts[1].to!int;
        minor    = parts[2].to!int;
        patch    = parts[3].to!int;
        revision = parts[4].to!int;
    }

    bool is_head() const {
        return name == "head";
    }

    // 3.4.1-1 and 3.4.9-2 are in the same series, 3.5.0-1 is not
    bool is_same_series_as(const Version other) const {
        return major == other.major && minor == other.minor;
    }

    int opCmp(const Version other) const {
        if (is_head) return other.is_head ? 0 : 1;
        if (other.is_head) return -1;

        auto result = cmp(
            [major, minor, patch, revision],
            [other.major, other.minor, other.patch, other.revision]
        );
        return result != 0 ? result : cmp(name, other.name);
    }
}


unittest {
    assert(Version("3.10.0-1") > Version("3.9.9-1"));
    assert(Version("3.2.1-2")  > Version("3.2.1-1"));
    assert(Version("head")     > Version("99.0.0-1"));
    assert(Version("3.4.1-1").is_same_series_as(Version("3.4.9-2")));
    assert(!Version("3.4.1-1").is_same_series_as(Version("3.5.0-1")));
}


// `rvm --ruby-version use 3.1.2`
//
// rvm will generate 'ruby-3.1.2', but rbenv(shell) will only generate '3.1.2'
// but rbenv(shell) will recognize 'ruby-3.1.2' too, so we do too
string remove_ruby_prefix(string ver) {
    return ver.chompPrefix("ruby-");
}


private bool match_version_prefix(string candidate, string ver) {
    if (ver.endsWith(".") || ver.endsWith("-")) {
        return candidate.startsWith(ver);
    }
    return candidate == ver || candidate.startsWith(ver ~ ".") || candidate.startsWith(ver ~ "-");
}


// An exact match wins, otherwise the first candidate that has the request
// as its prefix. Returns null when nothing matches.
string find_matching_version(string[] versions, string requested_version) {
    if (versions.canFind(requested_version)) {
        return requested_version;
    }

    foreach (candidate; versions) {
        if (match_version_prefix(candidate, requested_version)) {
            return candidate;
        }
    }
    return null;
}


unittest {
    auto versions = ["head", "3.4.10-2", "3.4.9-1", "3.3.8-1"];
    assert(find_matching_version(versions, "3.4.9-1") == "3.4.9-1");
    assert(find_matching_version(versions, "3.4") == "3.4.10-2");
    assert(find_matching_version(versions, "3.4.9-") == "3.4.9-1");
    assert(find_matching_version(versions, "3.40") is null);
    assert(find_matching_version([], "3.4") is null);
}
