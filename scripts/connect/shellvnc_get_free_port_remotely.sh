#!/bin/bash

# Imports
[ -z "${SHELLVNC_PATH}" ] && { echo "Source \"shellvnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shellvnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
. "../messages/_constants.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shellvnc_print_error.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./shellvnc_is_port_free_remotely.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
shellvnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

# Prints first free port_to_check after the given one.
# If no free port_to_check is found, prints an error message and returns 1.
#
# Usage: shellvnc_get_free_port_remotely <port_to_check> <host[:port=22]> [user] [password]
# Where:
# - "port_to_check": Port number to start searching from.
shellvnc_get_free_port_remotely() {
  if [ "$#" -lt 2 ]; then
    shellvnc_print_error "Usage: ${c_highlight}${FUNCNAME[0]} <port_to_check> <host[:port=22]> [user] [password]${c_return}" || return "$?"
    return 1
  fi
  local port_to_check="$1" && shift

  local host_with_port="$1" && shift

  local host="${host_with_port%%:*}"
  local port="${host_with_port##*:}"
  if [ "${port}" = "${host_with_port}" ]; then
    port=22
  fi

  local user="${1:-$(whoami)}" && shift

  local password="${1}" && shift
  if [ -z "${password}" ]; then
    password="$(read -r -s -p "Password for user \"${user}\" on host \"${host}\" (port ${port}): " password && echo "${password}")" || return "$?"
  fi

  local _port
  for ((_port = port_to_check; _port <= port_to_check + SHELLVNC_PORTS_NUMBER_TO_FIND_FREE; _port++)); do
    if shellvnc_is_port_free_remotely "${_port}" "${host}:${port}" "${user}" "${password}"; then
      echo "${_port}"
      return 0
    fi
  done

  shellvnc_print_error "No free port_to_check found (\"${c_highlight}${port_to_check}-$((port_to_check + SHELLVNC_PORTS_NUMBER_TO_FIND_FREE))${c_return}\") on \"${c_highlight}${host}:${port}${c_return}\"." || return "$?"
  return 1
}

shellvnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
