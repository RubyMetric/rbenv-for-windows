/* --------------------------------------------------------------
* current_versions:
*
*   Everything rbenv knows about the configured versions: the active
*   version, the global, local, shell and system ones.
*
*   It only reports. Unlike get_active_version(), it creates no file and
*   leaves the active version empty when nothing is set.
* -------------------------------------------------------------*/

module rbenv.current_versions;

import rbenv.active_version;
import rbenv.host          : get_system_version, SystemVersion;
import rbenv.version_files;

// Written in the D programming language.
// --------------------------------------------------------------


struct CurrentVersions {
    ActiveVersion active;
    string        global;
    LocalVersion  local;
    string        shell;
    SystemVersion system;
}


CurrentVersions get_current_versions() {
    CurrentVersions current;
    current.global = get_configured_global_version();
    current.local  = get_nearest_local_version();
    current.shell  = get_shell_version();
    current.system = get_system_version();

    current.active = determine_active_version(current.shell, current.local, current.global);
    return current;
}
