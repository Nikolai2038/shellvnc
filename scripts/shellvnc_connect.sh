#!/bin/bash

# Imports
[ -z "${SHELLVNC_PATH}" ] && { echo "Source \"shell-vnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shellvnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
. "./messages/_constants.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_print_error.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_print_info_increase_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_print_success_decrease_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_print_error_decrease_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./shell/shellvnc_check_requirements.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
shellvnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

# Usage: shellvnc_connect <host[:port=22]> [user] [password]
shellvnc_connect() {
  shellvnc_print_info_increase_prefix "Connecting..." || return "$?"

  shellvnc_check_requirements || return "$?"

  shellvnc_commands "${SHELLVNC_COMMANDS_ACTION_INSTALL}" vncviewer pactl ssh sshpass scp screen usbip || return "$?"

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
  vnc_port="$(sshpass "-p${password}" \
    ssh \
    -p "${port}" \
    "${n2038_extra_args_for_ssh_connections_to_vms[@]}" \
    "${user}@${host}" \
    "cat ${SHELLVNC_PATH_TO_FILE_WITH_USER_PORT}")" || return "$?"
  shellvnc_print_success_decrease_prefix "Getting VNC port from the remote server: success!" || return "$?"
  # ========================================

  # ========================================
  # Open SSH tunnels
  # ========================================
  # Name of the screen session
  local screen_session_name="shellvnc_${user}_on_${host}_port_${port}"

  # Terminate SSH forwarding if it is already running
  if screen -list | grep --quiet "${screen_session_name}"; then
    shellvnc_print_info_increase_prefix "Terminate \"screen\" session to forward SSH ports..." || return "$?"
    # Terminate screen session
    screen -S "${screen_session_name}" -X quit || return "$?"
    shellvnc_print_success_decrease_prefix "Terminate \"screen\" session to forward SSH ports: success!" || return "$?"
  fi

  # Passthrough ports via SSH
  shellvnc_print_info_increase_prefix "Start \"screen\" session to forward SSH ports..." || return "$?"
  screen -dm -S "${screen_session_name}" \
    sshpass "-p${password}" \
    ssh -N \
    -p "${port}" \
    "${n2038_extra_args_for_ssh_connections_to_vms[@]}" \
    -L "127.0.0.1:${vnc_port}:127.0.0.1:${vnc_port}" \
    "${user}@${host}" || return "$?"
  shellvnc_print_success_decrease_prefix "Start \"screen\" session to forward SSH ports: success!" || return "$?"

  # Because we run script in the background, we need to wait for a bit
  shellvnc_print_info_increase_prefix "Waiting for SSH ports to be forwarded..." || return "$?"
  local sleep_time_step=0.1
  local sleep_time_steps_current=0
  local sleep_time_steps_max=50
  while ! timeout 1 bash -c "</dev/tcp/127.0.0.1/${vnc_port}" > /dev/null 2>&1; do
    sleep "${sleep_time_step}" || return "$?"
    sleep_time_steps_current="$((sleep_time_steps_current + 1))"
    if [ "${sleep_time_steps_current}" -ge "${sleep_time_steps_max}" ]; then
      shellvnc_print_error_decrease_prefix "Waiting for SSH ports to be forwarded: failed!" || return "$?"
      return 1
    fi
  done
  shellvnc_print_success_decrease_prefix "Waiting for SSH ports to be forwarded: success!" || return "$?"
  # ========================================

  # ========================================
  # Connect to VNC server
  # ========================================
  declare -a vnc_args=(
    -PasswordFile="${path_to_vnc_password_locally}"

    # Disconnect other VNC sessions when connecting
    -Shared=0

    -MenuKey=Scroll_Lock
    -ViewOnly=0

    -AcceptClipboard=1
    -SendPrimary=1

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
    -FullColor

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

  shellvnc_print_info_increase_prefix "Connecting to VNC server..." || return "$?"
  local vncviewer_return_code=0
  vncviewer "${vnc_args[@]}" "127.0.0.1:${vnc_port}"
  vncviewer_return_code="$?"
  shellvnc_print_success_decrease_prefix "Connecting to VNC server: done!" || return "$?"
  # ========================================

  # ========================================
  # Terminate SSH forwarding
  # ========================================
  if screen -list | grep --quiet "${screen_session_name}"; then
    shellvnc_print_info_increase_prefix "Terminate \"screen\" session to forward SSH ports..." || return "$?"
    # Terminate screen session
    screen -S "${screen_session_name}" -X quit || return "$?"
    shellvnc_print_success_decrease_prefix "Terminate \"screen\" session to forward SSH ports: success!" || return "$?"
  fi
  # ========================================

  if [ "${vncviewer_return_code}" != "0" ]; then
    shellvnc_print_error_decrease_prefix "Connecting: failed!" || return "$?"
    return "${vncviewer_return_code}"
  fi

  shellvnc_print_success_decrease_prefix "Connecting: success!" || return "$?"
}

shellvnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
