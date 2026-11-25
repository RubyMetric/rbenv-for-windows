/* --------------------------------------------------------------
* errors:
*
*   A failure the user is expected to read and act on, e.g. a version that
*   is not installed. Code that detects such a failure throws RbenvError
*   instead of printing a message and exiting by itself; rbenv-exec.d
*   reports it as 'rbenv: <message>' and exits with its exit code.
* -------------------------------------------------------------*/

module rbenv.errors;

// Written in the D programming language.
// --------------------------------------------------------------


class RbenvError : Exception {
    int exit_code;

    this(string message, int exit_code = 1) {
        super(message);
        this.exit_code = exit_code;
    }
}
