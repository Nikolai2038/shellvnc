#!/bin/bash

# Imports
[ -z "${SHELLVNC_PATH}" ] && { echo "Source \"shellvnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shellvnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
. "../messages/_constants.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shellvnc_print_error.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
shellvnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

# Checks if the given port_to_check is free on the remote machine.
# Returns 0 if the port_to_check is free, 1 if it is not free.
#
# Usage: shellvnc_is_port_free_remotely <port_to_check> <host[:port=22]> [user] [password]
# Where:
# - "port_to_check": Port number to check.
shellvnc_is_port_free_remotely() {
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

  # Special args for every SSH connection to VMs
  declare -a n2038_extra_args_for_ssh_connections_to_vms=(
    # Timeout for the operation. Make sure to make it high enough to use SCP
    -o "ConnectTimeout=5"
  )

  if [ "${SHELLVNC_IS_DEVELOPMENT}" = "1" ]; then
    n2038_extra_args_for_ssh_connections_to_vms+=(
      # Because VMs every time has different keys, we do not check them. This is also needed to avoid "read: Interrupted system call" (when calling "sshpass" but ssh returns prompt to add key fingerprint);
      -o "StrictHostKeyChecking=no"
      # Redirect host writing, so we always can connect, if hosts was changes (VM recreated)
      -o "UserKnownHostsFile=/dev/null"
      # To not print warnings about adding hosts to the list of known hosts
      -o "LogLevel=quiet"
    )
  fi

  if sshpass "-p${password}" \
    ssh \
    -p "${port}" \
    "${n2038_extra_args_for_ssh_connections_to_vms[@]}" \
    "${user}@${host}" \
    "timeout 1 bash -c \"</dev/tcp/127.0.0.1/${port_to_check}\" 2> /dev/null"; then
    return "${FALSE}"
  fi

  return "${TRUE}"
}

shellvnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
