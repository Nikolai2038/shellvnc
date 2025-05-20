#!/bin/bash

# Imports
[ -z "${SHELLVNC_PATH}" ] && { echo "Source \"shellvnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shellvnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
# ...
shellvnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

# Generate a unique filename to store PID
shellvnc_get_pid_file() {
  local user="$1"
  local host="$2"
  local port="$3"
  local first_port="$4"
  local second_port="$5"
  local direction="$6"
  echo "/tmp/shellvnc_ssh_${user}_${host}_${port}_${first_port}_${second_port}_${direction}.pid"
}

shellvnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
