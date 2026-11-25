/* --------------------------------------------------------------
* version_display:
*
*   Turn structured active-version facts into user-facing messages and the
*   fake Ruby version string. Keep warning emission separate from formatting.
*
*   NotInstalled and GlobalVersionNotSet are display values, not version
*   names in the data model. They remain visible for starship/oh-my-posh
*   and compatibility with existing rbenv output.
* -------------------------------------------------------------*/

module rbenv.version_display;

import std.algorithm : canFind, startsWith;
import std.string : chompPrefix;
import core.stdc.stdlib : exit;

import rbenv.common;


void warn_active_version(ActiveVersion active) {
    final switch (active.state) {
        case ActiveVersionState.available:
            return;
        case ActiveVersionState.notInstalled:
            warn("rbenv: version " ~ active.name ~ " not installed");
            return;
        case ActiveVersionState.globalNotSet:
            warn("rbenv: No global version has been set, use rbenv global <version>");
            return;
    }
}


string format_active_version_name(ActiveVersion active) {
    final switch (active.state) {
        case ActiveVersionState.available:
            return active.name;
        case ActiveVersionState.notInstalled:
            return active.name ~ "NotInstalled";
        case ActiveVersionState.globalNotSet:
            // return "";
            // Now we don't return an empty string, but show the *informative version*,
            // to make starship/oh-my-posh user directly know what is wrong
            return "GlobalVersionNotSet";
    }
}


// Formatted "(set by ...)" message
string format_active_version_source(ActiveVersion active) {
    final switch (active.source) {
        case VersionSource.none:
            return "";
        case VersionSource.shell:
            return "(set by $env:RBENV_VERSION environment variable)";
        case VersionSource.local:
        case VersionSource.global:
            return "(set by " ~ active.source_path ~ ")";
    }
}


string format_ruby_version(ActiveVersion active) {
    return "ruby " ~ format_active_version_name(active) ~ " " ~ format_active_version_source(active);
}


string auto_fix_version_for_installed(string ver) {
    if (ver.startsWith("ruby-")) {
        ver = ver.chompPrefix("ruby-");
    }

    auto installed_version = find_installed_version(ver);
    if (installed_version !is null) {
        return installed_version;
    }

    // exit(0);
    // Now we don't exit instantly, but show the *informative version*,
    // to make starship/oh-my-posh user directly know what is wrong
    ActiveVersion active;
    active.name = ver;
    active.state = ActiveVersionState.notInstalled;
    warn_active_version(active);
    return format_active_version_name(active);
}


string auto_fix_version_for_remote(string ver) {

    auto versions = get_all_remote_versions();

    if (versions.canFind(ver)) {
        return ver;
    } else {
        foreach (s ; versions)  {
            if (match_version_prefix(s, ver)) { return s; }
        }
    }

    warn("rbenv: version " ~ ver ~ " not installed");
    exit(0);
}


// rdmd -unittest -main .\rbenv.d
unittest {
    auto arr  = get_all_remote_versions();
    auto arr2 = get_all_installed_versions();
    auto ret  = "2.7".auto_fix_version_for_installed;
    auto ret2 = "2.7".auto_fix_version_for_remote;
    // writeln(ret2);
}
