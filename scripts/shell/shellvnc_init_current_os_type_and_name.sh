#!/bin/bash

# Imports
[ -z "${SHELLVNC_PATH}" ] && { echo "Source \"shell-vnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shellvnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
. "../messages/_constants.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shellvnc_print_info_increase_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shellvnc_print_error.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shellvnc_print_text.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shellvnc_print_success_decrease_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
shellvnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

shellvnc_init_current_os_type_and_name() {
  shellvnc_print_info_increase_prefix "Initializing current OS type and name..." || return "$?"

  local current_kernel_name
  current_kernel_name="$(uname -s)" || return "$?"

  if [ -n "${MSYSTEM}" ]; then
    _SHELLVNC_CURRENT_OS_TYPE="${_SHELLVNC_OS_TYPE_WINDOWS}"
    _SHELLVNC_CURRENT_OS_NAME="${_SHELLVNC_OS_NAME_WINDOWS}"

    # Convert to lowercase and replace spaces with dashes
    _SHELLVNC_CURRENT_OS_VERSION="$(powershell -command "(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').ProductName" | sed -E 's/[^a-zA-Z0-9]+/-/g' | tr '[:upper:]' '[:lower:]' | sed -E 's/^windows-//')" || return "$?"

    # ========================================
    # Imitate "sudo" command for Windows
    # ========================================
    if [ "${_N2038_CURRENT_OS_TYPE}" = "${_N2038_OS_TYPE_WINDOWS}" ]; then
      # shellcheck disable=SC2317
      sudo() {
        local shellvnc_temp_file shellvnc_arg shellvnc_arg_escaped

        shellvnc_temp_file="$(mktemp --suffix ".sh")" || return "$?"
        echo "temp file: ${shellvnc_temp_file}"

        echo "return_code=0" >> "${shellvnc_temp_file}" || return "$?"
        while [ "$#" -gt 0 ]; do
          shellvnc_arg="$1" && shift
          shellvnc_arg_escaped="${shellvnc_arg//\\/\\\\}" || return "$?"
          shellvnc_arg_escaped="${shellvnc_arg_escaped//\"/\\\"}" || return "$?"
          shellvnc_arg_escaped="${shellvnc_arg_escaped//\$/\\\$}" || return "$?"
          echo -n "\"${shellvnc_arg_escaped}\" " >> "${shellvnc_temp_file}" || return "$?"
        done
        echo " || { return_code=\"\$?\" && read -p 'Error with return code \${return_code} occurred! Press any key to continue...' -n 1 -s -r; }" >> "${shellvnc_temp_file}" || return "$?"

        # Clear buffer (this helps for special keys like arrows)
        echo "while read -t 0.1 -n 1 -r; do :; done" >> "${shellvnc_temp_file}" || return "$?"
        echo "echo ''" >> "${shellvnc_temp_file}" || return "$?"

        # Remove temp file
        echo "rm \"${shellvnc_temp_file}\"" >> "${shellvnc_temp_file}" || return "$?"
        echo "exit \${return_code}" >> "${shellvnc_temp_file}" || return "$?"

        echo "========================================"
        cat "${shellvnc_temp_file}" || return "$?"
        echo "========================================"

        # TODO: Find cause: For some reason, with '--noprofile', '--norc' it will freeze (and then, executing by hand will be okay).
        powershell.exe -Command "Start-Process -FilePath 'C:\Program Files\Git\git-bash.exe' -Verb RunAs -ArgumentList '${shellvnc_temp_file}'" || return "$?"

        # Wait for the temp file to be removed - this will happen when the command is finished
        while [ -f "${shellvnc_temp_file}" ]; do
          sleep 1
        done

        return 0
      }
      # Export function, if we are in Bash. This way, MINGW will be able to see main functions when executing files.
      # Also, in "dash" if error encountered while sourcing, sourcing will be stoped - so we explicitly check if we are in Bash here.
      # shellcheck disable=SC3045
      [ -n "${BASH_VERSION}" ] && export -f sudo 2> /dev/null
    fi
    # ========================================
  elif [ "${current_kernel_name}" = "Linux" ]; then
    _SHELLVNC_CURRENT_OS_TYPE="${_SHELLVNC_OS_TYPE_LINUX}"

    # For Termux there is no "/etc/os-release" file, so we need to check it separately
    if [ -n "${TERMUX_VERSION}" ]; then
      _SHELLVNC_CURRENT_OS_NAME="${_SHELLVNC_OS_NAME_TERMUX}"
      _SHELLVNC_CURRENT_OS_VERSION="${TERMUX_VERSION}"
    else
      if [ ! -f "/etc/os-release" ]; then
        shellvnc_print_error "File \"/etc/os-release\" not found - probably, \"${c_highlight}${FUNCNAME[0]}${c_return}\" is not implemented for your OS." || return "$?"
        return 1
      fi

      _SHELLVNC_CURRENT_OS_NAME="$(sed -n 's/^ID=//p' /etc/os-release)" || return "$?"

      if [ -z "${_SHELLVNC_CURRENT_OS_NAME}" ]; then
        shellvnc_print_error "Could not determine the current OS name!" || return "$?"
        return 1
      fi

      if [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_ARCH}" ]; then
        # There is no version for Arch
        _SHELLVNC_CURRENT_OS_VERSION="rolling-release"
      else
        _SHELLVNC_CURRENT_OS_VERSION="$(sed -En 's/^VERSION_ID="?([^"]+)"?/\1/p' /etc/os-release)" || return "$?"
      fi
    fi
  elif [ "${current_kernel_name}" = "Darwin" ]; then
    _SHELLVNC_CURRENT_OS_TYPE="${_SHELLVNC_OS_TYPE_MACOS}"
    _SHELLVNC_CURRENT_OS_NAME="${_SHELLVNC_OS_NAME_MACOS}"
    shellvnc_print_error "Getting OS version is not implemented in \"${c_highlight}${FUNCNAME[0]}${c_return}\" for \"${c_highlight}${_SHELLVNC_CURRENT_OS_NAME}${c_return}\"!" || return "$?"
    return 1
  else
    shellvnc_print_error "Could not determine the current OS type!" || return "$?"
    return 1
  fi

  shellvnc_print_text "Current OS type: \"${c_highlight}${_SHELLVNC_CURRENT_OS_TYPE}${c_return}\"." || return "$?"
  shellvnc_print_text "Current OS name: \"${c_highlight}${_SHELLVNC_CURRENT_OS_NAME}${c_return}\"." || return "$?"
  shellvnc_print_text "Current OS version: \"${c_highlight}${_SHELLVNC_CURRENT_OS_VERSION}${c_return}\"." || return "$?"
  shellvnc_print_success_decrease_prefix "Initializing current OS type and name: success!" || return "$?"
}

shellvnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
