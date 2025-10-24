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

  if [ "${SHELLVNC_IS_COMPRESS}" = "1" ]; then
    # Enable compression
    extra_ssh_args+=(-C)
  fi

  if [ -z "${SHELLVNC_SSH_BEST_CIPHERS}" ]; then
    declare -a ciphers=()
    # shellcheck disable=SC2207
    ciphers=($(ssh -Q cipher))
    shellvnc_print_info "Supported client ciphers: ${c_highlight}${ciphers[*]}${c_return}." || return "$?"

    shellvnc_print_info_increase_prefix "Testing SSH ciphers to find the best one for encryption..." || return "$?"

    # Check ciphers and sort them by time from fastest to slowest
    local results=""

    local cipher="NONE"

    # ========================================
    # Test with default ciphers order
    # ========================================
    shellvnc_print_info "Testing cipher \"${c_highlight}${cipher}${c_return}\"..." || return "$?"

    local result
    {
      result="$(time (dd if=/dev/zero bs="${SHELLVNC_CIPHER_TEST_SIZE}" count="${SHELLVNC_CIPHER_TEST_COUNTS}" | sshpass -p"${password}" ssh -p "${port}" "${extra_ssh_args[@]}" "${user}@${host}" "cat > /dev/null") 2>&1 | head -n 3 | tail -n 1)" || return "$?"
    } 2> /dev/null

    local time_in_seconds
    time_in_seconds="$(echo "${result}" | sed -En 's/^.* (.+) .+, .+ .+$/\1/p')" || return "$?"

    results+="${time_in_seconds} ${cipher}
"
    shellvnc_print_info "Testing cipher \"${c_highlight}${cipher}${c_return}\": success! Time: \"${c_highlight}${time_in_seconds}${c_return}\" seconds." || return "$?"
    # ========================================

    # ========================================
    # Test all client ciphers
    # ========================================
    for cipher in "${ciphers[@]}"; do
      shellvnc_print_info "Testing cipher \"${c_highlight}${cipher}${c_return}\"..." || return "$?"

      # NOTE: We skip unsupported ciphers
      { result="$(time (dd if=/dev/zero bs="${SHELLVNC_CIPHER_TEST_SIZE}" count="${SHELLVNC_CIPHER_TEST_COUNTS}" | sshpass -p"${password}" ssh -p "${port}" -c "${cipher}" "${extra_ssh_args[@]}" "${user}@${host}" "cat > /dev/null") 2>&1 | head -n 3 | tail -n 1)"; } 2> /dev/null || {
        shellvnc_print_info "Testing cipher \"${c_highlight}${cipher}${c_return}\": skipped! The server side probably does not support it." || return "$?"
        continue
      }

      local time_in_seconds
      time_in_seconds="$(echo "${result}" | sed -En 's/^.* (.+) .+, .+ .+$/\1/p')" || return "$?"

      results+="${time_in_seconds}\t${cipher}
"

      shellvnc_print_info "Testing cipher \"${c_highlight}${cipher}${c_return}\": success! Time: \"${c_highlight}${time_in_seconds}${c_return}\" seconds." || return "$?"
    done
    # ========================================

    # Remove empty lines and sort ciphers from fastest to slowest
    results="$(echo "${results}" | grep -Ev '^$' | sort -n)" || return "$?"

    shellvnc_print_success_decrease_prefix "Testing SSH ciphers to find the best one for encryption: success!" || return "$?"

    shellvnc_print_info "Test results:" || return "$?"
    echo -e "${results}" >&2

    local list
    list="$(echo -n "${results}" | cut -f 2)" || return "$?"
    list="${list//$'\n'/,}" || return "$?"

    export SHELLVNC_SSH_BEST_CIPHERS="${list}"
  fi

  shellvnc_print_success "Best SSH ciphers for encryption: \"${c_highlight}${SHELLVNC_SSH_BEST_CIPHERS}${c_return}\"." || return "$?"

  # If "none" is not the fastest - we will use encryption
  if ! echo "${SHELLVNC_SSH_BEST_CIPHERS}" | grep -qE "^${NONE}"; then
    extra_ssh_args+=(
      # Compression algorithms to use with priority (from best to worst)
      # NOTE: Remove "none" from the list
      -c "${SHELLVNC_SSH_BEST_CIPHERS//",${NONE}"/}"
    )
  fi

  if [ "${SHELLVNC_IS_DEBUG}" = "1" ]; then
    # More logs
    extra_ssh_args+=(-v)
  fi

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
