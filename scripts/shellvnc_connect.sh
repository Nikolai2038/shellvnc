#!/bin/bash

# Imports
[ -z "${SHELLVNC_PATH}" ] && { echo "Source \"shellvnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shellvnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
. "./messages/_constants.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_print_error.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_print_text.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_print_info_increase_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_print_success_decrease_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./shell/shellvnc_check_requirements.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./connect/shellvnc_forward_port_via_ssh_L.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./connect/shellvnc_forward_port_via_ssh_R.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./connect/shellvnc_terminate_ssh_tunnel_L.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./connect/shellvnc_terminate_ssh_tunnel_R.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./connect/shellvnc_get_pid_file.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
shellvnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

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

  # This must be the same as in service
  local usbip_port_client=3240

  # This can be anything
  local usbip_port_server=3241

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

    local usb_device_to_forward
    for usb_device_to_forward in "${SHELLVNC_USB_DEVICES_TO_FORWARD[@]}"; do
      shellvnc_print_info_increase_prefix "Stop forwarding USB device \"${usb_device_to_forward}\"..." || return "$?"

      local bus_id_to_forward
      bus_id_to_forward="$(usbip --tcp-port "${usbip_port_client}" list -l | sed -En "s/^ - busid ([^ ]+) \\(${usb_device_to_forward}\\)\$/\\1/p")" || return "$?"
      shellvnc_print_text "Bus ID: ${c_highlight}${bus_id_to_forward}${c_return}." || return "$?"

      # Forward USB device
      sudo usbip --tcp-port "${usbip_port_client}" unbind -b "${bus_id_to_forward}" || true

      shellvnc_print_success_decrease_prefix "Stop forwarding USB device \"${usb_device_to_forward}\": success!" || return "$?"
    done

    # Terminate SSH tunnels
    shellvnc_terminate_ssh_tunnel_R "${user}" "${host}" "${port}" "${usbip_port_server}" "${usbip_port_client}" || true

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
    sleep 3

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
    # Open SSH tunnels
    shellvnc_forward_port_via_ssh_R "${user}" "${host}" "${port}" "${usbip_port_server}" "${usbip_port_client}" "${password}" \
      "${n2038_extra_args_for_ssh_connections_to_vms[@]}" || return "$?"

    local usb_device_to_forward
    for usb_device_to_forward in "${SHELLVNC_USB_DEVICES_TO_FORWARD[@]}"; do
      shellvnc_print_info_increase_prefix "Forwarding USB device \"${usb_device_to_forward}\"..." || return "$?"

      local bus_id_to_forward
      bus_id_to_forward="$(usbip --tcp-port "${usbip_port_client}" list -l | sed -En "s/^ - busid ([^ ]+) \\(${usb_device_to_forward}\\)\$/\\1/p")" || return "$?"
      shellvnc_print_text "Bus ID: ${c_highlight}${bus_id_to_forward}${c_return}." || return "$?"

      # Forward USB device
      sudo usbip --tcp-port "${usbip_port_client}" bind -b "${bus_id_to_forward}" || true

      shellvnc_print_success_decrease_prefix "Forwarding USB device \"${usb_device_to_forward}\": success!" || return "$?"

      shellvnc_print_info_increase_prefix "Checking if USB device \"${usb_device_to_forward}\" is forwarded..." || return "$?"

      sshpass "-p${password}" \
        ssh \
        -p "${port}" \
        "${n2038_extra_args_for_ssh_connections_to_vms[@]}" \
        "${user}@${host}" \
        "usbip --tcp-port \"${usbip_port_server}\" list -r 127.0.0.1" | grep -q "${usb_device_to_forward}" || return "$?"

      shellvnc_print_success_decrease_prefix "Checking if USB device \"${usb_device_to_forward}\" is forwarded: success!" || return "$?"

      shellvnc_print_info_increase_prefix "Connecting to USB device \"${usb_device_to_forward}\"..." || return "$?"
      sshpass "-p${password}" \
        ssh \
        -p "${port}" \
        "${n2038_extra_args_for_ssh_connections_to_vms[@]}" \
        "${user}@${host}" \
        "echo  \"${password}\" | sudo -S usbip --tcp-port \"${usbip_port_server}\" attach -r 127.0.0.1 -b \"${bus_id_to_forward}\"" || return "$?"
      shellvnc_print_success_decrease_prefix "Connecting to USB device \"${usb_device_to_forward}\": success!" || return "$?"
    done
    # ========================================
  } &

  # ========================================
  # VNC
  # ========================================
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
