#!/bin/bash

# Imports
[ -z "${SHELLVNC_PATH}" ] && { echo "Source \"shellvnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shellvnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
. "../messages/_constants.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shellvnc_print_error.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
shellvnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

# Checks if the given port_to_check is free on current machine.
# Returns 0 if the port_to_check is free, 1 if it is not free.
#
# Usage: shellvnc_is_port_free_locally <port_to_check>
# Where:
# - "port_to_check": Port number to check.
shellvnc_is_port_free_locally() {
  if [ "$#" -ne 1 ]; then
    shellvnc_print_error "Usage: ${c_highlight}${FUNCNAME[0]} <port_to_check>${c_return}" || return "$?"
    return 1
  fi

  local port_to_check="$1" && shift

  if timeout 1 bash -c "</dev/tcp/127.0.0.1/${port_to_check}" 2> /dev/null; then
    return "${FALSE}"
  fi

  return "${TRUE}"
}

shellvnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
