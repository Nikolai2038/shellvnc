#!/bin/bash

# Imports
[ -z "${SHELLVNC_PATH}" ] && { echo "Source \"shellvnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shellvnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
. "../messages/_constants.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shellvnc_print_error.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shellvnc_print_info_increase_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shellvnc_print_success_decrease_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./shellvnc_get_pid_file.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
shellvnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

# Template function to terminate a running SSH tunnel.
#
# Usage: shellvnc_terminate_ssh_tunnel <user> <host> <port> <first_port> <second_port> <direction>
# Where:
# - "user": SSH user;
# - "host": SSH host;
# - "port": SSH port;
# - "first_port": Local port to forward;
# - "second_port": Remote port to forward;
# - "direction": SSH direction flag (-L for local forwarding, -R for remote forwarding).
shellvnc_terminate_ssh_tunnel() {
  local direction="$1" && shift
  if [ "${direction}" != "-L" ] && [ "${direction}" != "-R" ]; then
    shellvnc_print_error "Invalid direction \"${c_highlight}${direction}${c_return}\". Use \"${c_highlight}-L${c_return}\" for local forwarding or \"${c_highlight}-R${c_return}\" for remote forwarding." || return "$?"
    return 1
  fi

  local user="$1" && shift
  local host="$1" && shift
  local port="$1" && shift
  local first_port="$1" && shift
  local second_port="$1" && shift

  local pid_file
  pid_file="$(shellvnc_get_pid_file "$user" "$host" "$port" "$first_port" "$second_port" "$direction")" || return "$?"

  if [ ! -f "${pid_file}" ]; then
    return 0
  fi

  local ssh_tunnel_pid
  ssh_tunnel_pid="$(< "${pid_file}")" || return "$?"

  shellvnc_print_info_increase_prefix "Terminate SSH tunnel (PID is in file \"${c_highlight}${pid_file}${c_return}\")..." || return "$?"
  kill -TERM "${ssh_tunnel_pid}" || true
  shellvnc_print_success_decrease_prefix "Terminate SSH tunnel (PID is  in file \"${c_highlight}${pid_file}${c_return}\"): success!" || return "$?"

  rm -f "${pid_file}" || return "$?"
}

shellvnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
