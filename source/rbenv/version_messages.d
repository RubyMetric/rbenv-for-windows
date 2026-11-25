/* --------------------------------------------------------------
* version_messages:
*
*   Turn structured active-version facts into user-facing messages and the
*   fake Ruby version string. Keep warning emission separate from formatting.
*
*   NotInstalled and GlobalVersionNotSet are display values, not version
*   names in the data model. They remain visible for starship/oh-my-posh
*   and compatibility with existing rbenv output.
*
*   Used by everything that shows the active version to someone: the fake
*   ruby.exe, the shims and 'rbenv current'.
* -------------------------------------------------------------*/

module rbenv.version_messages;

import rbenv.active_version;
import rbenv.console : warn;

// Written in the D programming language.
// --------------------------------------------------------------


void warn_active_version(ActiveVersion active) {
    final switch (active.state) {
        case ActiveVersionState.available:
            return;
        case ActiveVersionState.not_installed:
            warn("rbenv: version " ~ active.name ~ " not installed");
            return;
        case ActiveVersionState.global_not_set:
            warn("rbenv: No global version has been set, use rbenv global <version>");
            return;
    }
}


string format_active_version_name(ActiveVersion active) {
    final switch (active.state) {
        case ActiveVersionState.available:
            return active.name;
        case ActiveVersionState.not_installed:
            // exit(0);
            // Now we don't exit instantly, but show the *informative version*,
            // to make starship/oh-my-posh user directly know what is wrong
            return active.name ~ "NotInstalled";
        case ActiveVersionState.global_not_set:
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
