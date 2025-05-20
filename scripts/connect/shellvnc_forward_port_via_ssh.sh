#!/bin/bash

# Imports
[ -z "${SHELLVNC_PATH}" ] && { echo "Source \"shellvnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shellvnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
. "../messages/_constants.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shellvnc_print_error.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shellvnc_print_info_increase_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shellvnc_print_success_decrease_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shellvnc_print_error_decrease_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./shellvnc_get_pid_file.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
shellvnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

# Template function to establish an SSH tunnel for port forwarding.
#
# Usage: shellvnc_forward_port_via_ssh <user> <host> <port> <first_port> <second_port> <password> <direction> [<extra_ssh_args>...]
# Where:
# - "user": SSH user;
# - "host": SSH host;
# - "port": SSH port;
# - "first_port": Local port to forward;
# - "second_port": Remote port to forward;
# - "password": SSH password;
# - "direction": SSH direction flag (-L for local forwarding, -R for remote forwarding);
# - "extra_ssh_args": Additional SSH arguments (optional).
shellvnc_forward_port_via_ssh() {
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
  local password="$1" && shift

  local extra_ssh_args=("$@")

  local pid_file
  pid_file="$(shellvnc_get_pid_file "$user" "$host" "$port" "$first_port" "$second_port" "$direction")" || return "$?"

  # Start SSH tunnel
  shellvnc_print_info_increase_prefix "Start SSH tunnel \"${c_highlight}${direction}${c_return}\" \"${c_highlight}127.0.0.1:${first_port}${c_return}\" <-> \"${c_highlight}127.0.0.1:${second_port}${c_return}\" (PID is in file \"${c_highlight}${pid_file}${c_return}\")..." || return "$?"
  sshpass -p"${password}" \
    ssh -N \
    -p "${port}" \
    "${extra_ssh_args[@]}" \
    "${direction}" "127.0.0.1:${first_port}:127.0.0.1:${second_port}" \
    "${user}@${host}" &
  local ssh_pid=$!

  # On Linux, last process ID will be "sshpass" - all correct.
  # On Windows (Git Bash), last process ID will be SSH - parent ID. So we need to get the child process ID.
  if [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_WINDOWS}" ]; then
    shellvnc_print_text "SSH tunnel PPID: ${c_highlight}${ssh_pid}${c_return}." || return "$?"
    ssh_pid="$(ps | sed -En "s/^.\s+([0-9]+)\s+${ssh_pid}.*$/\1/p" | head -n 1)" || return "$?"
  fi
  shellvnc_print_text "SSH tunnel PID: ${c_highlight}${ssh_pid}${c_return}." || return "$?"

  echo "$ssh_pid" > "$pid_file"
  shellvnc_print_success_decrease_prefix "Start SSH tunnel \"${c_highlight}${direction}${c_return}\" \"${c_highlight}127.0.0.1:${first_port}${c_return}\" <-> \"${c_highlight}127.0.0.1:${second_port}${c_return}\" (PID is in file \"${c_highlight}${pid_file}${c_return}\"): success!" || return "$?"

  # Wait for port
  local port_to_wait="${first_port}"
  if [ "${direction}" = "-R" ]; then
    port_to_wait="${second_port}"
  fi

  shellvnc_print_info_increase_prefix "Waiting for port \"${c_highlight}${port_to_wait}${c_return}\" to become ready..." || return "$?"
  local sleep_time_step=0.1
  local sleep_time_steps_current=0
  local sleep_time_steps_max=50
  while ! timeout 1 bash -c "</dev/tcp/127.0.0.1/${port_to_wait}" &> /dev/null; do
    sleep "${sleep_time_step}" || return "$?"
    sleep_time_steps_current=$((sleep_time_steps_current + 1))
    if [ "${sleep_time_steps_current}" -ge "${sleep_time_steps_max}" ]; then
      shellvnc_print_error_decrease_prefix "Waiting for port \"${c_highlight}${port_to_wait}${c_return}\" to become ready: failed! Timeout exceeded." || return "$?"
      return 1
    fi
  done
  shellvnc_print_success_decrease_prefix "Waiting for port \"${c_highlight}${port_to_wait}${c_return}\" to become ready: success!" || return "$?"
}

shellvnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
