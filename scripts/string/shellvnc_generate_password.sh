#!/bin/bash

# Imports
[ -z "${SHELLVNC_PATH}" ] && { echo "Source \"shell-vnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shellvnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
# ...
shellvnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

shellvnc_generate_password() {
  local length="${1:-32}" && { shift || true; }
  # Because we read from "/dev" and forcefully close the file descriptor, we need to ignore the error code
  tr -dc 'A-Za-z0-9' < /dev/urandom | head -c "${length}" || true
}

shellvnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
