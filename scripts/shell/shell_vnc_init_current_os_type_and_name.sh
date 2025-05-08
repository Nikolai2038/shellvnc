#!/bin/bash

# Imports
[ -z "${SHELL_VNC_PATH}" ] && { echo "Source \"shell-vnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shell_vnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
. "../messages/_constants.sh" || shell_vnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shell_vnc_print_info_increase_prefix.sh" || shell_vnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shell_vnc_print_error.sh" || shell_vnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shell_vnc_print_text.sh" || shell_vnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shell_vnc_print_success_decrease_prefix.sh" || shell_vnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
shell_vnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

shell_vnc_init_current_os_type_and_name() {
  shell_vnc_print_info_increase_prefix "Initializing current OS type and name..." || return "$?"

  local current_kernel_name
  current_kernel_name="$(uname -s)" || return "$?"

  if [ -n "${MSYSTEM}" ]; then
    _SHELL_VNC_CURRENT_OS_TYPE="${_SHELL_VNC_OS_TYPE_WINDOWS}"
    _SHELL_VNC_CURRENT_OS_NAME="${_SHELL_VNC_OS_NAME_WINDOWS}"

    # Convert to lowercase and replace spaces with dashes
    _SHELL_VNC_CURRENT_OS_VERSION="$(powershell -command "(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').ProductName" | sed -E 's/[^a-zA-Z0-9]+/-/g' | tr '[:upper:]' '[:lower:]' | sed -E 's/^windows-//')" || return "$?"
  elif [ "${current_kernel_name}" = "Linux" ]; then
    _SHELL_VNC_CURRENT_OS_TYPE="${_SHELL_VNC_OS_TYPE_LINUX}"

    # For Termux there is no "/etc/os-release" file, so we need to check it separately
    if [ -n "${TERMUX_VERSION}" ]; then
      _SHELL_VNC_CURRENT_OS_NAME="${_SHELL_VNC_OS_NAME_TERMUX}"
      _SHELL_VNC_CURRENT_OS_VERSION="${TERMUX_VERSION}"
    else
      if [ ! -f "/etc/os-release" ]; then
        shell_vnc_print_error "File \"/etc/os-release\" not found - probably, \"${c_highlight}${FUNCNAME[0]}${c_return}\" is not implemented for your OS." || return "$?"
        return 1
      fi

      _SHELL_VNC_CURRENT_OS_NAME="$(sed -n 's/^ID=//p' /etc/os-release)" || return "$?"

      if [ -z "${_SHELL_VNC_CURRENT_OS_NAME}" ]; then
        shell_vnc_print_error "Could not determine the current OS name!" || return "$?"
        return 1
      fi

      if [ "${_SHELL_VNC_CURRENT_OS_NAME}" = "${_SHELL_VNC_OS_NAME_ARCH}" ]; then
        # There is no version for Arch
        _SHELL_VNC_CURRENT_OS_VERSION="rolling-release"
      else
        _SHELL_VNC_CURRENT_OS_VERSION="$(sed -En 's/^VERSION_ID="?([^"]+)"?/\1/p' /etc/os-release)" || return "$?"
      fi
    fi
  elif [ "${current_kernel_name}" = "Darwin" ]; then
    _SHELL_VNC_CURRENT_OS_TYPE="${_SHELL_VNC_OS_TYPE_MACOS}"
    _SHELL_VNC_CURRENT_OS_NAME="${_SHELL_VNC_OS_NAME_MACOS}"
    shell_vnc_print_error "Getting OS version is not implemented in \"${c_highlight}${FUNCNAME[0]}${c_return}\" for \"${c_highlight}${_SHELL_VNC_CURRENT_OS_NAME}${c_return}\"!" || return "$?"
    return 1
  else
    shell_vnc_print_error "Could not determine the current OS type!" || return "$?"
    return 1
  fi

  shell_vnc_print_text "Current OS type: \"${c_highlight}${_SHELL_VNC_CURRENT_OS_TYPE}${c_return}\"." || return "$?"
  shell_vnc_print_text "Current OS name: \"${c_highlight}${_SHELL_VNC_CURRENT_OS_NAME}${c_return}\"." || return "$?"
  shell_vnc_print_text "Current OS version: \"${c_highlight}${_SHELL_VNC_CURRENT_OS_VERSION}${c_return}\"." || return "$?"
  shell_vnc_print_success_decrease_prefix "Initializing current OS type and name: success!" || return "$?"
}

shell_vnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
