#!/bin/bash

# Imports
[ -z "${SHELLVNC_PATH}" ] && { echo "Source \"shell-vnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shellvnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
. "../messages/_constants.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shellvnc_print_info_increase_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shellvnc_print_text.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shellvnc_print_error.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shellvnc_print_success_decrease_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
shellvnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

SHELLVNC_COMMANDS_ACTION_INSTALL="install"
SHELLVNC_COMMANDS_ACTION_UNINSTALL="uninstall"

# Installs or removes packages for specified commands.
# Returns 0 if all the commands are installed, otherwise returns other values.
#
# Usage: shellvnc_commands <action> <command...>
shellvnc_commands() {
  if [ "$#" -lt 2 ]; then
    shellvnc_print_error "Usage: ${c_highlight}${FUNCNAME[0]} <${SHELLVNC_COMMANDS_ACTION_INSTALL}|${SHELLVNC_COMMANDS_ACTION_UNINSTALL}> <command...>${c_return}" || return "$?"
    return 1
  fi

  local action="$1" && shift

  local action_word_1
  local action_word_2
  if [ "${action}" = "${SHELLVNC_COMMANDS_ACTION_INSTALL}" ]; then
    action_word_1="Installing"
    action_word_2="install"
  elif [ "${action}" = "${SHELLVNC_COMMANDS_ACTION_UNINSTALL}" ]; then
    action_word_1="Uninstalling"
    action_word_2="uninstall"
  else
    shellvnc_print_error "Unknown action \"${c_highlight}${action}${c_return}\"!" || return "$?"
    return 1
  fi

  local commands="$*"
  shellvnc_print_info_increase_prefix "${action_word_1} commands ${c_highlight}${commands}${c_return}..." || return "$?"

  if [ "$#" -lt 1 ]; then
    shellvnc_print_error "Usage: ${c_highlight}${FUNCNAME[0]} <command...>${c_return}" || return "$?"
    return 1
  fi

  while [ "$#" -gt 0 ]; do
    local command="$1" && shift

    if [ "${action}" = "${SHELLVNC_COMMANDS_ACTION_INSTALL}" ]; then
      if type "${command}" > /dev/null 2>&1; then
        shellvnc_print_text "Command \"${c_highlight}${command}${c_return}\" is installed! Skipping!" || return "$?"
        continue
      else
        shellvnc_print_text "Command \"${c_highlight}${command}${c_return}\" is not installed!" || return "$?"

        # shellcheck disable=SC2320
        echo "${command}" >> "${SHELLVNC_INSTALLED_COMMANDS_PATH}" || return "$?"
      fi
    elif [ "${action}" = "${SHELLVNC_COMMANDS_ACTION_UNINSTALL}" ]; then
      if type "${command}" > /dev/null 2>&1; then
        shellvnc_print_text "Command \"${c_highlight}${command}${c_return}\" is installed!" || return "$?"
      else
        shellvnc_print_text "Command \"${c_highlight}${command}${c_return}\" is not installed! Skipping!" || return "$?"
        continue
      fi
    else
      shellvnc_print_error "Unknown action \"${c_highlight}${action}${c_return}\"!" || return "$?"
      return 1
    fi

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
      if [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_ARCH}" ]; then
        packages_names="tigervnc"
      elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_FEDORA}" ]; then
        packages_names="tigervnc"
      elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_DEBIAN}" ]; then
        packages_names="tigervnc-viewer"
      else
        echo "Installing command \"${c_highlight}${command}${c_return}\" is not implemented for \"${_SHELLVNC_CURRENT_OS_NAME}\"!" >&2
      fi
    elif [ "${command}" = "telnet" ]; then
      packages_names="inetutils"
    elif [ "${command}" = "debtap" ]; then
      packages_names="debtap"
      is_aur=1
    elif [ "${command}" = "tput" ]; then
      if [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_TERMUX}" ]; then
        packages_names="ncurses-utils"
      elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_ARCH}" ]; then
        packages_names="ncurses"
      elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_FEDORA}" ]; then
        packages_names="ncurses"
      elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_DEBIAN}" ]; then
        packages_names="ncurses-bin"
      else
        echo "Installing command \"${c_highlight}${command}${c_return}\" is not implemented for \"${_SHELLVNC_CURRENT_OS_NAME}\"!" >&2
      fi
    elif [ "${command}" = "pstree" ]; then
      packages_names="psmisc"
    elif [ "${command}" = "sshpass" ]; then
      packages_names="sshpass"
    elif [ "${command}" = "ssh" ]; then
      if [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_ARCH}" ]; then
        packages_names="openssh"
      elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_FEDORA}" ]; then
        packages_names="openssh-clients"
      elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_DEBIAN}" ]; then
        packages_names="openssh-client"
      else
        echo "Installing command \"${c_highlight}${command}${c_return}\" is not implemented for \"${_SHELLVNC_CURRENT_OS_NAME}\"!" >&2
      fi
    elif [ "${command}" = "pactl" ]; then
      if [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_ARCH}" ]; then
        packages_names="libpulse"
      elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_FEDORA}" ]; then
        packages_names="pulseaudio-utils"
      elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_DEBIAN}" ]; then
        packages_names="pulseaudio-utils"
      else
        echo "Installing command \"${c_highlight}${command}${c_return}\" is not implemented for \"${_SHELLVNC_CURRENT_OS_NAME}\"!" >&2
      fi
    fi
    # ========================================

    local command_to_execute=""

    # ========================================
    # Define installation steps
    # ========================================
    # Add hint for installing "jq" in Windows
    if [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_WINDOWS}" ]; then
      if [ "${command}" = "jq" ]; then
        command_to_execute="sudo curl -L -o /usr/bin/jq.exe https://github.com/jqlang/jq/releases/latest/download/jq-win64.exe"
      else
        shellvnc_print_error "Installing command \"${c_highlight}${command}${c_return}\" is not implemented for \"${_SHELLVNC_OS_NAME_WINDOWS}\"!" || return "$?"
        return 1
      fi
    elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_TERMUX}" ]; then
      if [ "${action}" = "${SHELLVNC_COMMANDS_ACTION_INSTALL}" ]; then
        command_to_execute="pkg update && pkg install -y ${packages_names}"
      elif [ "${action}" = "${SHELLVNC_COMMANDS_ACTION_UNINSTALL}" ]; then
        command_to_execute="pkg remove -y ${packages_names}"
      else
        shellvnc_print_error "Unknown action \"${c_highlight}${action}${c_return}\"!" || return "$?"
        return 1
      fi
    elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_ARCH}" ]; then
      if [ "${is_aur}" = "1" ]; then
        if [ "${action}" = "${SHELLVNC_COMMANDS_ACTION_INSTALL}" ]; then
          command_to_execute="yay --sync --refresh --needed --noconfirm ${packages_names}"
        elif [ "${action}" = "${SHELLVNC_COMMANDS_ACTION_UNINSTALL}" ]; then
          command_to_execute="yay -Runs --noconfirm ${packages_names}"
        else
          shellvnc_print_error "Unknown action \"${c_highlight}${action}${c_return}\"!" || return "$?"
          return 1
        fi
      else
        if [ "${action}" = "${SHELLVNC_COMMANDS_ACTION_INSTALL}" ]; then
          command_to_execute="sudo pacman --sync --refresh --needed --noconfirm ${packages_names}"
        elif [ "${action}" = "${SHELLVNC_COMMANDS_ACTION_UNINSTALL}" ]; then
          command_to_execute="sudo pacman -Runs --noconfirm ${packages_names}"
        else
          shellvnc_print_error "Unknown action \"${c_highlight}${action}${c_return}\"!" || return "$?"
          return 1
        fi
      fi
    elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_FEDORA}" ]; then
      if [ "${action}" = "${SHELLVNC_COMMANDS_ACTION_INSTALL}" ]; then
        command_to_execute="sudo dnf install -y ${packages_names}"
      elif [ "${action}" = "${SHELLVNC_COMMANDS_ACTION_UNINSTALL}" ]; then
        command_to_execute="sudo dnf remove -y ${packages_names}"
      else
        shellvnc_print_error "Unknown action \"${c_highlight}${action}${c_return}\"!" || return "$?"
        return 1
      fi
    elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_DEBIAN}" ]; then
      if [ "${action}" = "${SHELLVNC_COMMANDS_ACTION_INSTALL}" ]; then
        command_to_execute="sudo apt-get update && sudo apt-get install -y ${packages_names}"
      elif [ "${action}" = "${SHELLVNC_COMMANDS_ACTION_UNINSTALL}" ]; then
        command_to_execute="sudo apt-get remove -y ${packages_names}"
      else
        shellvnc_print_error "Unknown action \"${c_highlight}${action}${c_return}\"!" || return "$?"
        return 1
      fi
    else
      shellvnc_print_error "Installing commands are not implemented for \"${_SHELLVNC_CURRENT_OS_NAME}\"!" || return "$?"
      return 1
    fi
    # ========================================

    # ========================================
    # Define post installation steps
    # ========================================
    if [ "${command}" = "debtap" ]; then
      command_to_execute="${command_to_execute} && sudo debtap -u"
    fi
    # ========================================

    # ========================================
    # Installation itself, or just print hint
    # ========================================
    if [ "${SHELLVNC_AUTO_INSTALL_PACKAGES}" = "1" ]; then
      shellvnc_print_info_increase_prefix "${action_word_1} \"${c_highlight}${command}${c_return}\" for ${_SHELLVNC_CURRENT_OS_NAME^} via command \"${c_highlight}${command_to_execute}${c_return}\"..." || return "$?"
      eval "${command_to_execute}" || return "$?"
      shellvnc_print_success_decrease_prefix "${action_word_1} \"${c_highlight}${command}${c_return}\" for ${_SHELLVNC_CURRENT_OS_NAME^} via command \"${c_highlight}${command_to_execute}${c_return}\": success!" || return "$?"
      return 0
    else
      shellvnc_print_text "You can ${action_word_2} \"${c_highlight}${command}${c_return}\" for ${_SHELLVNC_CURRENT_OS_NAME^} via command: \"${c_highlight}${command_to_execute}${c_return}\"" || return "$?"
      shellvnc_print_error "Please ${action_word_2} it manually or set \"${c_highlight}SHELLVNC_AUTO_INSTALL_PACKAGES=1${c_return}\" to ${action_word_2} it automatically!" || return "$?"
      return 1
    fi
    # ========================================
  done

  shellvnc_print_success_decrease_prefix "${action_word_1} commands ${c_highlight}${commands}${c_return}: success!" || return "$?"
}

shellvnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
