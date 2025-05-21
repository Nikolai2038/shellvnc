#!/bin/bash

# Imports
[ -z "${SHELLVNC_PATH}" ] && { echo "Source \"shellvnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shellvnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
. "./messages/_constants.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_print_text.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_print_error.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_print_info_increase_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_print_success_decrease_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./shell/shellvnc_check_requirements.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./shell/shellvnc_commands.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./shellvnc_reconfigure.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
shellvnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

shellvnc_uninstall() {
  shellvnc_print_info_increase_prefix "Uninstallation..." || return "$?"

  if [ "$#" -ne 1 ]; then
    shellvnc_print_error "Usage: ${c_highlight}${FUNCNAME[0]} <server|client|both>${c_return}" || return "$?"
    return 1
  fi

  shellvnc_check_requirements || return "$?"

  local type
  type="$1" && shift

  if [ "${type}" = "server" ] || [ "${type}" = "both" ]; then
    shellvnc_print_info_increase_prefix "Uninstalling server..." || return "$?"
    if [ "${_SHELLVNC_CURRENT_OS_TYPE}" != "${_SHELLVNC_OS_TYPE_LINUX}" ]; then
      shellvnc_print_error "Uninstallation of server is only supported on Linux OS type!" || return "$?"
      return 1
    fi

    # ========================================
    # USB IP
    # ========================================
    if sudo [ -f /etc/modules-load.d/shellvnc_vhci_hcd.conf ]; then
      shellvnc_print_info_increase_prefix "Removing USB IP kernel module..." || return "$?"

      # Unload kernel module right now
      if lsmod | awk '{print $1}' | grep -q vhci_hcd; then
        sudo modprobe -r vhci_hcd || return "$?"
      fi

      # Unload kernel module on system start
      sudo rm /etc/modules-load.d/shellvnc_vhci_hcd.conf || return "$?"

      shellvnc_print_success_decrease_prefix "Removing USB IP kernel module: success!" || return "$?"
    fi
    # ========================================

    # ========================================
    # Desktop entry
    # ========================================
    if [ -f /etc/xdg/openbox/autostart.bkp ]; then
      shellvnc_print_info_increase_prefix "Restoring default config \"${c_highlight}/etc/xdg/openbox/autostart${c_return}\" from \"${c_highlight}/etc/xdg/openbox/autostart.bkp${c_return}\"..." || return "$?"
      sudo cp -T /etc/xdg/openbox/autostart.bkp /etc/xdg/openbox/autostart || return "$?"
      sudo rm /etc/xdg/openbox/autostart.bkp || return "$?"
      shellvnc_print_success_decrease_prefix "Restoring default config \"${c_highlight}/etc/xdg/openbox/autostart${c_return}\" from \"${c_highlight}/etc/xdg/openbox/autostart.bkp${c_return}\": success!" || return "$?"
    fi

    if [ -f /usr/share/xsessions/shellvnc.desktop ]; then
      sudo rm /usr/share/xsessions/shellvnc.desktop || return "$?"
    fi
    # ========================================

    # ========================================
    # PolKit rules
    # ========================================
    shellvnc_print_info_increase_prefix "Removing PolKit rules..." || return "$?"

    if sudo [ -f /etc/polkit-1/rules.d/99-shellvnc-allow-admins-to-change-network.rules ]; then
      sudo rm /etc/polkit-1/rules.d/99-shellvnc-allow-admins-to-change-network.rules || return "$?"
    fi

    if sudo [ -f /etc/polkit-1/rules.d/99-shellvnc-allow-admins-to-reboot.rules ]; then
      sudo rm /etc/polkit-1/rules.d/99-shellvnc-allow-admins-to-reboot.rules || return "$?"
    fi

    if sudo [ -f /etc/polkit-1/rules.d/99-shellvnc-allow-admins-to-configure-usb-devices.rules ]; then
      sudo rm /etc/polkit-1/rules.d/99-shellvnc-allow-admins-to-configure-usb-devices.rules || return "$?"
    fi

    shellvnc_print_success_decrease_prefix "Removing PolKit rules: success!" || return "$?"
    # ========================================

    if [ -f /etc/tigervnc/vncserver-config-defaults.bkp ]; then
      shellvnc_print_info_increase_prefix "Restoring default config \"${c_highlight}/etc/tigervnc/vncserver-config-defaults${c_return}\" from \"${c_highlight}/etc/tigervnc/vncserver-config-defaults.bkp${c_return}\"..." || return "$?"
      sudo cp -T /etc/tigervnc/vncserver-config-defaults.bkp /etc/tigervnc/vncserver-config-defaults || return "$?"
      sudo rm /etc/tigervnc/vncserver-config-defaults.bkp || return "$?"
      shellvnc_print_success_decrease_prefix "Restoring default config \"${c_highlight}/etc/tigervnc/vncserver-config-defaults${c_return}\" from \"${c_highlight}/etc/tigervnc/vncserver-config-defaults.bkp${c_return}\": success!" || return "$?"
    fi

    if [ -f "${SHELLVNC_ENABLED_USERS_PATH}" ]; then
      shellvnc_print_info_increase_prefix "Clearing VNC users..." || return "$?"
      rm "${SHELLVNC_ENABLED_USERS_PATH}" || return "$?"
      shellvnc_print_success_decrease_prefix "Clearing VNC users: success!" || return "$?"
    fi
    shellvnc_reconfigure || return "$?"

    shellvnc_print_success_decrease_prefix "Uninstalling server: success!" || return "$?"
  fi

  if [ "${type}" = "client" ] || [ "${type}" = "both" ]; then
    shellvnc_print_info_increase_prefix "Uninstalling client..." || return "$?"

    # ========================================
    # USB IP
    # ========================================
    if [ "${_SHELLVNC_CURRENT_OS_TYPE}" = "${_SHELLVNC_OS_TYPE_LINUX}" ]; then
      if sudo [ -f /etc/modules-load.d/shellvnc_usbip_host.conf ]; then
        shellvnc_print_info_increase_prefix "Removing USB IP kernel module..." || return "$?"

        # Unload kernel module right now
        if lsmod | awk '{print $1}' | grep -q usbip_host; then
          sudo modprobe -r usbip_host || return "$?"
        fi

        # Unload kernel module on system start
        sudo rm /etc/modules-load.d/shellvnc_usbip_host.conf || return "$?"

        shellvnc_print_success_decrease_prefix "Removing USB IP kernel module: success!" || return "$?"
      fi
    elif [ "${_SHELLVNC_CURRENT_OS_TYPE}" = "${_SHELLVNC_OS_TYPE_WINDOWS}" ]; then
      # Windows does not need any configuration
      :
    else
      shellvnc_print_error "USB IP is not supported on OS type \"${c_highlight}${_SHELLVNC_CURRENT_OS_TYPE}${c_return}\"!" || return "$?"
      return 1
    fi
    # ========================================

    shellvnc_print_success_decrease_prefix "Uninstalling client: success!" || return "$?"
  fi

  shellvnc_print_info_increase_prefix "Uninstalling installed commands..." || return "$?"
  if [ -f "${SHELLVNC_INSTALLED_COMMANDS_PATH}" ]; then
    declare -a commands_to_uninstall=()
    # shellcheck disable=SC2207
    commands_to_uninstall=($(cat "${SHELLVNC_INSTALLED_COMMANDS_PATH}")) || return "$?"

    shellvnc_commands "${_SHELLVNC_COMMANDS_ACTION_UNINSTALL}" "${commands_to_uninstall[@]}" || return "$?"
    rm "${SHELLVNC_INSTALLED_COMMANDS_PATH}" || return "$?"
  else
    shellvnc_print_text "All commands were already installed before \"${c_highlight}shellvnc${c_return}\" installation - none will be uninstalled." || return "$?"
  fi
  shellvnc_print_success_decrease_prefix "Uninstalling installed commands: success!" || return "$?"

  shellvnc_print_success_decrease_prefix "Uninstallation: success!" || return "$?"
}

shellvnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
