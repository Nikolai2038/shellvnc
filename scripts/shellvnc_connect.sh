#!/bin/bash

# Imports
[ -z "${SHELLVNC_PATH}" ] && { echo "Source \"shellvnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shellvnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
. "./messages/_constants.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_print_error.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_print_info_increase_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_print_success_decrease_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_print_error_decrease_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./shell/shellvnc_check_requirements.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
shellvnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

# Generate a unique filename to store PID
_shellvnc_get_pid_file() {
  local user="$1"
  local host="$2"
  local port="$3"
  local first_port="$4"
  local second_port="$5"
  local direction="$6"
  echo "/tmp/shellvnc_ssh_${user}_${host}_${port}_${first_port}_${second_port}_${direction}.pid"
}

# Template function to establish an SSH tunnel for port forwarding.
#
# Usage: _shellvnc_forward_port_via_ssh <user> <host> <port> <first_port> <second_port> <password> <direction> [<extra_ssh_args>...]
# Where:
# - "user": SSH user;
# - "host": SSH host;
# - "port": SSH port;
# - "first_port": Local port to forward;
# - "second_port": Remote port to forward;
# - "password": SSH password;
# - "direction": SSH direction flag (-L for local forwarding, -R for remote forwarding);
# - "extra_ssh_args": Additional SSH arguments (optional).
_shellvnc_forward_port_via_ssh() {
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
  pid_file="$(_shellvnc_get_pid_file "$user" "$host" "$port" "$first_port" "$second_port" "$direction")" || return "$?"

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

# Template function to terminate a running SSH tunnel.
#
# Usage: _shellvnc_terminate_ssh_tunnel <user> <host> <port> <first_port> <second_port> <direction>
# Where:
# - "user": SSH user;
# - "host": SSH host;
# - "port": SSH port;
# - "first_port": Local port to forward;
# - "second_port": Remote port to forward;
# - "direction": SSH direction flag (-L for local forwarding, -R for remote forwarding).
_shellvnc_terminate_ssh_tunnel() {
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
  pid_file="$(_shellvnc_get_pid_file "$user" "$host" "$port" "$first_port" "$second_port" "$direction")" || return "$?"

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

# Forward local port to remote via SSH (-L).
#
# Usage: shellvnc_forward_port_via_ssh_L <user> <host> <port> <first_port> <second_port> <password> [<extra_ssh_args>...]
# Where:
# - "user": SSH user;
# - "host": SSH host;
# - "port": SSH port;
# - "first_port": Local port to forward;
# - "second_port": Remote port to forward;
# - "password": SSH password;
# - "extra_ssh_args": Additional SSH arguments (optional).
shellvnc_forward_port_via_ssh_L() {
  _shellvnc_forward_port_via_ssh -L "$@" || return "$?"
}

# Forward remote port to local via SSH (-R).
#
# Usage: shellvnc_forward_port_via_ssh_R <user> <host> <port> <first_port> <second_port> <password> [<extra_ssh_args>...]
# Where:
# - "user": SSH user;
# - "host": SSH host;
# - "port": SSH port;
# - "first_port": Local port to forward;
# - "second_port": Remote port to forward;
# - "password": SSH password;
# - "extra_ssh_args": Additional SSH arguments (optional).
shellvnc_forward_port_via_ssh_R() {
  _shellvnc_forward_port_via_ssh -R "$@" || return "$?"
}

# Terminate a local-to-remote SSH port forwarding (-L).
#
# Usage: shellvnc_terminate_ssh_tunnel_L <user> <host> <port> <first_port> <second_port>
# Where:
# - "user": SSH user;
# - "host": SSH host;
# - "port": SSH port;
# - "first_port": Local port to forward;
# - "second_port": Remote port to forward.
shellvnc_terminate_ssh_tunnel_L() {
  _shellvnc_terminate_ssh_tunnel -L "$@" || return "$?"
}

# Terminate a remote-to-local SSH port forwarding (-R).
#
# Usage: shellvnc_terminate_ssh_tunnel_R <user> <host> <port> <first_port> <second_port>
# Where:
# - "user": SSH user;
# - "host": SSH host;
# - "port": SSH port;
# - "first_port": Local port to forward;
# - "second_port": Remote port to forward.
shellvnc_terminate_ssh_tunnel_R() {
  _shellvnc_terminate_ssh_tunnel -R "$@" || return "$?"
}

# Connect to a VNC server.
#
# Usage: shellvnc_connect <host[:port=22]> [user] [password]
shellvnc_connect() {
  shellvnc_print_info_increase_prefix "Connecting..." || return "$?"

  shellvnc_check_requirements || return "$?"

  shellvnc_commands "${_SHELLVNC_COMMANDS_ACTION_INSTALL}" vncviewer pactl ssh sshpass scp usbip || return "$?"

  if [ "$#" -lt 1 ]; then
    shellvnc_print_error "Usage: ${c_highlight}${FUNCNAME[0]} <host[:port=22]> [user] [password]${c_return}" || return "$?"
    return 1
  fi
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
    -o "ConnectTimeout=15"
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

  # ========================================
  # Get VNC password for the target user.
  # We use VNC passwords to protect VNC connections from other users.
  # ========================================
  shellvnc_print_info_increase_prefix "Getting VNC password from the remote server..." || return "$?"

  local target_os_name
  target_os_name="$(sshpass "-p${password}" \
    ssh \
    -p "${port}" \
    "${n2038_extra_args_for_ssh_connections_to_vms[@]}" \
    "${user}@${host}" \
    "sed -n 's/^ID=//p' /etc/os-release")" || return "$?"

  if [ -z "${target_os_name}" ]; then
    shellvnc_print_error "Could not determine the target OS name!" || return "$?"
    return 1
  fi

  # Path to file in the target system, where VNC password is stored
  local path_to_vnc_password=""
  if [ "${target_os_name}" = "${_SHELLVNC_OS_NAME_ARCH}" ] || [ "${target_os_name}" = "${_SHELLVNC_OS_NAME_FEDORA}" ]; then
    path_to_vnc_password=".config/tigervnc/passwd"
  elif [ "${target_os_name}" = "${_SHELLVNC_OS_NAME_DEBIAN}" ]; then
    path_to_vnc_password=".vnc/passwd"
  else
    shellvnc_throw_error_not_implemented "${LINENO}" || return "$?"
  fi

  # Path to file in the current system, to which we will copy VNC password before connecting
  local path_to_vnc_password_locally="${SHELLVNC_DATA_PATH}/passwd_for_${user}_on_host_${host}_port_${port}"

  # Copy VNC password from remote host to local machine
  sshpass "-p${password}" \
    scp \
    -P "${port}" \
    "${n2038_extra_args_for_ssh_connections_to_vms[@]}" \
    "${user}@${host}:${path_to_vnc_password}" \
    "${path_to_vnc_password_locally}" || return "$?"

  shellvnc_print_success_decrease_prefix "Getting VNC password from the remote server: success!" || return "$?"
  # ========================================

  # ========================================
  # Get port of VNC server for the target user
  # ========================================
  shellvnc_print_info_increase_prefix "Getting VNC port from the remote server..." || return "$?"
  local vnc_port
  vnc_port="$(
    sshpass "-p${password}" \
      ssh \
      -p "${port}" \
      "${n2038_extra_args_for_ssh_connections_to_vms[@]}" \
      "${user}@${host}" \
      "cat \"${SHELLVNC_PATH_TO_FILE_WITH_USER_PORT}\""
  )" || return "$?"
  shellvnc_print_success_decrease_prefix "Getting VNC port from the remote server: success!" || return "$?"
  # ========================================

  local pulseaudio_port_client=4716
  local pulseaudio_port_server=4715
  # On Windows, we can use only default port, because firewall depends on it.
  # TODO: In the future, this probably can be customized.
  if [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_WINDOWS}" ]; then
    pulseaudio_port_client=4713
  fi

  # We must close tunnels and stop services in reverse order to make them properly exit.
  # shellcheck disable=SC2317
  function close_all_ssh_tunnels() {
    shellvnc_print_info_increase_prefix "Closing all SSH tunnels..." || return "$?"

    shellvnc_print_warning "You can ignore errors in this section!" || return "$?"

    # ========================================
    # Close VNC
    # ========================================
    shellvnc_print_info_increase_prefix "Closing VNC tunnel..." || return "$?"

    shellvnc_terminate_ssh_tunnel_L "${user}" "${host}" "${port}" "${vnc_port}" "${vnc_port}" || true

    shellvnc_print_success_decrease_prefix "Closing VNC tunnel: success!" || return "$?"
    # ========================================

    # ========================================
    # Close USBIP
    # ========================================
    shellvnc_print_info_increase_prefix "Closing USBIP tunnel..." || return "$?"

    # TODO: Close USBIP
    # ...

    shellvnc_print_success_decrease_prefix "Closing USBIP tunnel: success!" || return "$?"
    # ========================================

    # ========================================
    # Close PulseAudio
    # ========================================
    # Close PulseAudio tunnel
    shellvnc_print_info_increase_prefix "Closing PulseAudio tunnel..." || return "$?"
    shellvnc_terminate_ssh_tunnel_R "${user}" "${host}" "${port}" "${pulseaudio_port_server}" "${pulseaudio_port_client}" || true
    shellvnc_print_success_decrease_prefix "Closing PulseAudio tunnel: success!" || return "$?"

    # NOTE: Here we can unload PulseAudio server on the server, but it will cause issues when reconnecting sessions - new will start PulseAudio, but then older session kill it.
    # # Unload PulseAudio server on the server
    # shellvnc_print_info_increase_prefix "Unloading PulseAudio server on the server..." || return "$?"
    # sshpass "-p${password}" \
    #   ssh \
    #   -p "${port}" \
    #   "${n2038_extra_args_for_ssh_connections_to_vms[@]}" \
    #   "${user}@${host}" \
    #   "pactl unload-module module-tunnel-sink" || true
    # shellvnc_print_success_decrease_prefix "Unloading PulseAudio server on the server: success!" || return "$?"

    # Unload PulseAudio server on the client
    shellvnc_print_info_increase_prefix "Unloading PulseAudio server on the client..." || return "$?"
    if [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_WINDOWS}" ]; then
      # This will cause "Connection failure: Connection terminated"
      pactl unload-module module-native-protocol-tcp || true

      # So we restart PulseAudio service
      powershell.exe -Command "Start-Process -Wait powershell -Verb RunAs -ArgumentList 'Restart-Service PulseAudio'" || true
    else
      pactl unload-module module-native-protocol-tcp || true
    fi
    shellvnc_print_success_decrease_prefix "Unloading PulseAudio server on the client: success!" || return "$?"
    # ========================================

    shellvnc_print_warning "Now please don't ignore errors!" || return "$?"

    shellvnc_print_success_decrease_prefix "Closing all SSH tunnels: success!" || return "$?"
  }
  # Add return handler
  trap "close_all_ssh_tunnels; trap - RETURN" RETURN || return "$?"

  close_all_ssh_tunnels || return "$?"

  {
    # Wait until VNC is connected and the virtual session is catched
    sleep 5

    # ========================================
    # PulseAudio
    # ========================================
    shellvnc_print_info_increase_prefix "Starting PulseAudio server..." || return "$?"

    # Start PulseAudio server on the client
    if [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_WINDOWS}" ]; then
      pactl load-module module-native-protocol-tcp || return "$?"
    else
      pactl load-module module-native-protocol-tcp port=${pulseaudio_port_client} listen=127.0.0.1 || return "$?"
    fi

    # Check if PulseAudio server is running
    PULSE_SERVER=tcp:127.0.0.1:${pulseaudio_port_client} pactl info || return "$?"

    shellvnc_print_success_decrease_prefix "Starting PulseAudio server: success!" || return "$?"

    # Terminate SSH tunnels
    shellvnc_terminate_ssh_tunnel_R "${user}" "${host}" "${port}" "${pulseaudio_port_server}" "${pulseaudio_port_client}" || return "$?"

    # Open SSH tunnels
    shellvnc_forward_port_via_ssh_R "${user}" "${host}" "${port}" "${pulseaudio_port_server}" "${pulseaudio_port_client}" "${password}" \
      "${n2038_extra_args_for_ssh_connections_to_vms[@]}" || return "$?"

    # Check if PulseAudio server is forwarded
    shellvnc_print_info_increase_prefix "Checking if PulseAudio server is forwarded..." || return "$?"
    sshpass "-p${password}" \
      ssh \
      -p "${port}" \
      "${n2038_extra_args_for_ssh_connections_to_vms[@]}" \
      "${user}@${host}" \
      "PULSE_SERVER=tcp:127.0.0.1:${pulseaudio_port_server} pactl info" || return "$?"
    shellvnc_print_success_decrease_prefix "Checking if PulseAudio server is forwarded: success!" || return "$?"

    # Connect to the PulseAudio server
    shellvnc_print_info_increase_prefix "Connecting to PulseAudio server..." || return "$?"
    sshpass "-p${password}" \
      ssh \
      -p "${port}" \
      "${n2038_extra_args_for_ssh_connections_to_vms[@]}" \
      "${user}@${host}" \
      "pactl load-module module-tunnel-sink server=tcp:127.0.0.1:${pulseaudio_port_server} && sleep 3 && pactl set-default-sink tunnel-sink.tcp:127.0.0.1:${pulseaudio_port_server}" || return "$?"
    shellvnc_print_success_decrease_prefix "Connecting to PulseAudio server: success!" || return "$?"
    # ========================================

    # ========================================
    # TODO: USBIP
    # ========================================
    # ...
    # ========================================
  } &

  # ========================================
  # VNC
  # ========================================
  # Terminate SSH tunnels
  shellvnc_terminate_ssh_tunnel_L "${user}" "${host}" "${port}" "${vnc_port}" "${vnc_port}" || return "$?"

  # Open SSH tunnels
  shellvnc_forward_port_via_ssh_L "${user}" "${host}" "${port}" "${vnc_port}" "${vnc_port}" "${password}" \
    "${n2038_extra_args_for_ssh_connections_to_vms[@]}" || return "$?"

  declare -a vnc_args=(
    -PasswordFile="${path_to_vnc_password_locally}"

    # Disconnect other VNC sessions when connecting
    -Shared=0

    -MenuKey=Scroll_Lock
    -ViewOnly=0
    -Maximize=1

    -AcceptClipboard=1

    # Because we use SSH tunnels, we do not need to use IPv6
    -UseIPv6=0

    # We select quality level ourselves
    -AutoSelect=0

    # Probably the best one for low bandwidth networks and Internet connections
    -PreferredEncoding=Tight
    # Enable custom compression
    -CustomCompressLevel=1
    -CompressLevel=2
    # Disable JPEG Compression
    -NoJpeg=0
    -QualityLevel=8
    # 17 ms is for 60 Hz
    -PointerEventInterval=17
    # 0 meaning 8 colors, 1 meaning 64 colors (the default), 2 meaning 256 colors
    -LowColorLevel=2
    -FullColor=1

    # TODO: Use this when connecting on physical machine
    # # Transfer raw
    # -PreferredEncoding=Raw
    # # Disable custom compression
    # -CustomCompressLevel=0
    # -CompressLevel=9
    # # Disable JPEG compression
    # -NoJPEG=1
    # -QualityLevel=9
    # # If 17 ms is for 60 Hz, then 4 ms is for 240 Hz
    # -PointerEventInterval=4
    # # 0 meaning 8 colors, 1 meaning 64 colors (the default), 2 meaning 256 colors
    # -LowColorLevel=2
    # -FullColor

    # Increase clipboard size to 100 Mb
    -MaxCutText="$((1024 * 1024 * 100))"

    -RemoteResize=1

    -SecurityTypes=VncAuth

    # Do not show some dialogs
    -AlertOnFatalError=0
    -ReconnectOnError=0

    -FullscreenSystemKeys=1
  )

  if [ "${SHELLVNC_IS_DEVELOPMENT}" = "1" ]; then
    vnc_args+=(
      # Default is "*:stderr:30"
      -Log="*:stderr:30"
    )
  else
    vnc_args+=(
      # Disable logging on production (this might change in the future)
      -Log="*:stderr:0"
    )
  fi

  # TODO: Optimize connection
  # DISPLAY=:1 vncconfig -set FrameRate=30

  shellvnc_print_info_increase_prefix "Connecting to VNC server..." || return "$?"

  declare -a vncviewer_command=(
    vncviewer "${vnc_args[@]}" "127.0.0.1:${vnc_port}"
  )
  shellvnc_print_text "Command: ${c_highlight}${vncviewer_command[*]}${c_return}" || return "$?"
  "${vncviewer_command[@]}" || return "$?"

  shellvnc_print_success_decrease_prefix "Connecting to VNC server: done!" || return "$?"
  # ========================================

  # Terminate SSH tunnels
  close_all_ssh_tunnels || return "$?"

  # Clear return handler
  trap - RETURN || return "$?"

  shellvnc_print_success_decrease_prefix "Connecting: done!" || return "$?"
}

shellvnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
