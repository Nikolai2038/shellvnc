#!/bin/bash

# Imports
[ -z "${SHELL_VNC_PATH}" ] && { echo "Source \"shell-vnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shell_vnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
. "../messages/_constants.sh" || shell_vnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shell_vnc_print_info_increase_prefix.sh" || shell_vnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shell_vnc_print_text.sh" || shell_vnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shell_vnc_print_error.sh" || shell_vnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shell_vnc_print_success_decrease_prefix.sh" || shell_vnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
shell_vnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

# Checks if the specified commands are installed.
# Returns 0 if all the commands are installed, otherwise returns other values.
#
# Usage: shell_vnc_commands_must_be_installed <command...>
shell_vnc_commands_must_be_installed() {
  local commands="$*"
  shell_vnc_print_info_increase_prefix "Checking commands installation: ${c_highlight}${commands}${c_return}..." || return "$?"

  if [ "$#" -lt 1 ]; then
    shell_vnc_print_error "Usage: ${c_highlight}${FUNCNAME[0]} <command...>${c_return}" || return "$?"
    return 1
  fi

  while [ "$#" -gt 0 ]; do
    local command="$1" && shift

    if ! type "${command}" > /dev/null 2>&1; then
      shell_vnc_print_text "Command \"${c_highlight}${command}${c_return}\" is not installed!" || return "$?"

      # ========================================
      # Define package name for the command.
      # This can differ from OS to OS - this can be broken.
      # Right now I am testing only on Arch.
      # ========================================
      local is_aur=0
      local packages_names="${command}"
      if [ "${command}" = "wl-copy" ]; then
        packages_names="wl-clipboard"
      elif [ "${command}" = "man" ]; then
        packages_names="man-db man-pages"
      elif [ "${command}" = "genisoimage" ]; then
        packages_names="cdrtools"
      elif [ "${command}" = "plasma-activities-cli6" ]; then
        packages_names="plasma-activities"
      elif [ "${command}" = "netstat" ]; then
        packages_names="net-tools"
      elif [ "${command}" = "_init_completion" ]; then
        packages_names="bash-completion"
      elif [ "${command}" = "remote-viewer" ]; then
        packages_names="virt-viewer"
      elif [ "${command}" = "vncviewer" ]; then
        packages_names="tigervnc"
      elif [ "${command}" = "telnet" ]; then
        packages_names="inetutils"
      elif [ "${command}" = "debtap" ]; then
        packages_names="debtap"
        is_aur=1
      elif [ "${command}" = "tput" ]; then
        if [ "${_SHELL_VNC_CURRENT_OS_NAME}" = "${_SHELL_VNC_OS_NAME_TERMUX}" ]; then
          packages_names="ncurses-utils"
        elif [ "${_SHELL_VNC_CURRENT_OS_NAME}" = "${_SHELL_VNC_OS_NAME_ARCH}" ]; then
          packages_names="ncurses"
        elif [ "${_SHELL_VNC_CURRENT_OS_NAME}" = "${_SHELL_VNC_OS_NAME_FEDORA}" ]; then
          packages_names="ncurses"
        elif [ "${_SHELL_VNC_CURRENT_OS_NAME}" = "${_SHELL_VNC_OS_NAME_DEBIAN}" ]; then
          packages_names="ncurses-bin"
        else
          echo "Installing command \"${c_highlight}${command}${c_return}\" is not implemented for \"${_SHELL_VNC_CURRENT_OS_NAME}\"!" >&2
        fi
      elif [ "${command}" = "pstree" ]; then
        packages_names="psmisc"
      elif [ "${command}" = "sshpass" ]; then
        packages_names="sshpass"
      fi
      # ========================================

      local command_to_install=""

      # ========================================
      # Define installation steps
      # ========================================
      # Add hint for installing "jq" in Windows
      if [ "${_SHELL_VNC_CURRENT_OS_NAME}" = "${_SHELL_VNC_OS_NAME_WINDOWS}" ]; then
        if [ "${command}" = "jq" ]; then
          command_to_install="sudo curl -L -o /usr/bin/jq.exe https://github.com/jqlang/jq/releases/latest/download/jq-win64.exe"
        else
          shell_vnc_print_error "Installing command \"${c_highlight}${command}${c_return}\" is not implemented for \"${_SHELL_VNC_OS_NAME_WINDOWS}\"!" || return "$?"
          return 1
        fi
      elif [ "${_SHELL_VNC_CURRENT_OS_NAME}" = "${_SHELL_VNC_OS_NAME_TERMUX}" ]; then
        command_to_install="pkg update && pkg install -y ${packages_names}"
      elif [ "${_SHELL_VNC_CURRENT_OS_NAME}" = "${_SHELL_VNC_OS_NAME_ARCH}" ]; then
        if [ "${is_aur}" = "1" ]; then
          command_to_install="yay --sync --refresh --needed --noconfirm ${packages_names}"
        else
          command_to_install="sudo pacman --sync --refresh --needed --noconfirm ${packages_names}"
        fi
      elif [ "${_SHELL_VNC_CURRENT_OS_NAME}" = "${_SHELL_VNC_OS_NAME_FEDORA}" ]; then
        command_to_install="sudo dnf install -y ${packages_names}"
      elif [ "${_SHELL_VNC_CURRENT_OS_NAME}" = "${_SHELL_VNC_OS_NAME_DEBIAN}" ]; then
        command_to_install="sudo apt-get update && sudo apt-get install -y ${packages_names}"
      elif [ "${_SHELL_VNC_CURRENT_OS_NAME}" = "${_SHELL_VNC_OS_NAME_MACOS}" ]; then
        shell_vnc_print_error "Installing commands \"${c_highlight}${command}${c_return}\" are not implemented for \"${_SHELL_VNC_OS_NAME_MACOS}\"!" || return "$?"
        return 1
      fi
      # ========================================

      # ========================================
      # Define post installation steps
      # ========================================
      if [ "${command}" = "debtap" ]; then
        command_to_install="${command_to_install} && sudo debtap -u"
      fi
      # ========================================

      # ========================================
      # Installation itself, or just print hint
      # ========================================
      if [ "${SHELL_VNC_AUTO_INSTALL_PACKAGES}" = "1" ]; then
        shell_vnc_print_info_increase_prefix "Installing \"${c_highlight}${command}${c_return}\" for ${_SHELL_VNC_CURRENT_OS_NAME^} via command \"${c_highlight}${command_to_install}${c_return}\"..." || return "$?"
        eval "${command_to_install}" || return "$?"
        shell_vnc_print_success_decrease_prefix "Installing \"${c_highlight}${command}${c_return}\" for ${_SHELL_VNC_CURRENT_OS_NAME^} via command \"${c_highlight}${command_to_install}${c_return}\": success!" || return "$?"
        return 0
      else
        shell_vnc_print_text "You can install \"${c_highlight}${command}${c_return}\" for ${_SHELL_VNC_CURRENT_OS_NAME^} via command: \"${c_highlight}${command_to_install}${c_return}\"" || return "$?"
        shell_vnc_print_error "Please install it manually or set \"${c_highlight}SHELL_VNC_AUTO_INSTALL_PACKAGES=1${c_return}\" to install it automatically!" || return "$?"
        return 1
      fi
      # ========================================
    fi
  done

  shell_vnc_print_success_decrease_prefix "Checking commands installation: ${c_highlight}${commands}${c_return}: success!" || return "$?"
}

shell_vnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
