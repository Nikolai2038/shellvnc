#!/bin/bash

# Imports
[ -z "${SHELLVNC_PATH}" ] && { echo "Source \"shell-vnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shellvnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
. "../messages/_constants.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shellvnc_print_info_increase_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shellvnc_print_text.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shellvnc_print_error.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shellvnc_print_warning.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
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

    # (Only for Arch): If the package need to be installed from AUR (via "yay")
    local is_aur=0

    # (Only for Windows): If the package is an installer (1) or a portable executable (0)
    local is_windows_installer=0

    # Even if we can by default consider that the package name is the same as the command name, we don't want to accidentally install wrong package.
    # And because this solution will has defined number of commands, we can easily add new commands to the list and make it more reliable.
    # Linux: Required packages for the command;
    # Windows: URL to download the executable for command.
    local package_name_or_link=""

    if [ "${command}" = "vncviewer" ]; then
      if [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_ARCH}" ]; then
        package_name_or_link="tigervnc"
      elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_FEDORA}" ]; then
        package_name_or_link="tigervnc"
      elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_DEBIAN}" ]; then
        package_name_or_link="tigervnc-viewer"
      elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_WINDOWS}" ]; then
        package_name_or_link="https://sourceforge.net/projects/tigervnc/files/stable/${TIGERVNC_VERSION_FOR_WINDOWS}/vncviewer64-${TIGERVNC_VERSION_FOR_WINDOWS}.exe/download"
      fi
    elif [ "${command}" = "jq" ]; then
      if [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_ARCH}" ]; then
        package_name_or_link="jq"
      elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_FEDORA}" ]; then
        package_name_or_link="jq"
      elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_DEBIAN}" ]; then
        package_name_or_link="jq"
      elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_WINDOWS}" ]; then
        package_name_or_link="https://github.com/jqlang/jq/releases/latest/download/jq-win64.exe"
      fi
    elif [ "${command}" = "vncserver" ]; then
      if [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_ARCH}" ]; then
        package_name_or_link="tigervnc"
      elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_FEDORA}" ]; then
        package_name_or_link="tigervnc-server"
      elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_DEBIAN}" ]; then
        package_name_or_link="tigervnc-standalone-server"
      fi
    elif [ "${command}" = "tput" ]; then
      if [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_TERMUX}" ]; then
        package_name_or_link="ncurses-utils"
      elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_ARCH}" ]; then
        package_name_or_link="ncurses"
      elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_FEDORA}" ]; then
        package_name_or_link="ncurses"
      elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_DEBIAN}" ]; then
        package_name_or_link="ncurses-bin"
      fi
    elif [ "${command}" = "ssh" ]; then
      if [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_ARCH}" ]; then
        package_name_or_link="openssh"
      elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_FEDORA}" ]; then
        package_name_or_link="openssh-clients"
      elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_DEBIAN}" ]; then
        package_name_or_link="openssh-client"
      fi
    elif [ "${command}" = "pactl" ]; then
      if [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_ARCH}" ]; then
        package_name_or_link="libpulse"
      elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_FEDORA}" ]; then
        package_name_or_link="pulseaudio-utils"
      elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_DEBIAN}" ]; then
        package_name_or_link="pulseaudio-utils"
      elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_WINDOWS}" ]; then
        shellvnc_print_warning "When installer shows up, please remember to enable \"${c_highlight}Allow module loading${c_return}\"!" || return "$?"
        package_name_or_link="https://github.com/pgaskin/pulseaudio-win32/releases/download/${PULSEAUDIO_VERSION_FOR_WINDOWS}/pasetup.exe"
        is_windows_installer=1
      fi
    elif [ "${command}" = "i3" ]; then
      if [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_ARCH}" ]; then
        package_name_or_link="i3-wm"
      elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_FEDORA}" ]; then
        package_name_or_link="i3"
      elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_DEBIAN}" ]; then
        package_name_or_link="i3-wm"
      fi
    else
      # Commands which have the same package name for all Linux distributions
      if [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_ARCH}" ] \
        || [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_FEDORA}" ] \
        || [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_DEBIAN}" ]; then
        if [ "${command}" = "pstree" ]; then
          package_name_or_link="psmisc"
        else
          local __same_command
          for __same_command in which sed grep git ssh scp screen sshpass usbip openbox; do
            if [ "${command}" = "${__same_command}" ]; then
              package_name_or_link="${__same_command}"
            fi
          done
        fi
      fi
    fi

    if [ -z "${package_name_or_link}" ]; then
      shellvnc_print_error "Installing command \"${c_highlight}${command}${c_return}\" is not implemented for OS \"${c_highlight}${_SHELLVNC_CURRENT_OS_NAME}${c_return}\"!" || return "$?"
      return 1
    fi
    # ========================================

    local command_to_execute=""

    # ========================================
    # Define installation steps
    # ========================================
    # Add hint for installing "jq" in Windows
    if [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_WINDOWS}" ]; then
      local executable_path link_path

      executable_path="/usr/bin/${command}.exe" || return "$?"
      link_path="/usr/bin/${command}" || return "$?"

      if [ "${action}" = "${SHELLVNC_COMMANDS_ACTION_INSTALL}" ]; then
        if [ "${is_windows_installer}" = "0" ]; then
          # 1. Download executable file
          # 2. Create symlink so checks if this command is installed will work now
          command_to_execute="sudo curl --fail -L -o \"${executable_path}\" \"${package_name_or_link}\" && sudo ln -sf \"${executable_path}\" \"${link_path}\""
        else
          local installer_file_name
          installer_file_name="$(basename "${executable_path}")" || return "$?"

          # 1. Download installer
          # 2. Run installer
          # 3. Remove installer
          command_to_execute="sudo curl --fail -L -o \"${installer_file_name}\" \"${package_name_or_link}\" && ./${installer_file_name} || { error_code=\"\$?\" && rm \"${installer_file_name}\"; shellvnc_print_error \"Error occurred while trying to download and run the installer!\" || return \"\$?\"; return \"\${error_code}\"; }; rm \"${installer_file_name}\"" || return "$?"
        fi
      elif [ "${action}" = "${SHELLVNC_COMMANDS_ACTION_UNINSTALL}" ]; then
        if [ "${is_windows_installer}" = "0" ]; then
          # 1. Delete executable file
          # 2. Remove symlink
          command_to_execute="sudo rm -rf \"${executable_path}\" && sudo unlink \"${link_path}\"" || return "$?"
        else
          # TODO: Implement uninstallation for Windows
          shellvnc_print_error "Uninstalling \"${c_highlight}${command}${c_return}\" is not implemented for \"${c_highlight}${_SHELLVNC_CURRENT_OS_NAME}${c_return}\"!" || return "$?"
          return 1
        fi
      else
        shellvnc_print_error "Unknown action \"${c_highlight}${action}${c_return}\"!" || return "$?"
        return 1
      fi
    elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_TERMUX}" ]; then
      if [ "${action}" = "${SHELLVNC_COMMANDS_ACTION_INSTALL}" ]; then
        command_to_execute="pkg update && pkg install -y ${package_name_or_link}"
      elif [ "${action}" = "${SHELLVNC_COMMANDS_ACTION_UNINSTALL}" ]; then
        command_to_execute="pkg remove -y ${package_name_or_link}"
      else
        shellvnc_print_error "Unknown action \"${c_highlight}${action}${c_return}\"!" || return "$?"
        return 1
      fi
    elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_ARCH}" ]; then
      if [ "${is_aur}" = "1" ]; then
        if [ "${action}" = "${SHELLVNC_COMMANDS_ACTION_INSTALL}" ]; then
          command_to_execute="yay --sync --refresh --needed --noconfirm ${package_name_or_link}"
        elif [ "${action}" = "${SHELLVNC_COMMANDS_ACTION_UNINSTALL}" ]; then
          command_to_execute="yay -Runs --noconfirm ${package_name_or_link}"
        else
          shellvnc_print_error "Unknown action \"${c_highlight}${action}${c_return}\"!" || return "$?"
          return 1
        fi
      else
        if [ "${action}" = "${SHELLVNC_COMMANDS_ACTION_INSTALL}" ]; then
          command_to_execute="sudo pacman --sync --refresh --needed --noconfirm ${package_name_or_link}"
        elif [ "${action}" = "${SHELLVNC_COMMANDS_ACTION_UNINSTALL}" ]; then
          command_to_execute="sudo pacman -Runs --noconfirm ${package_name_or_link}"
        else
          shellvnc_print_error "Unknown action \"${c_highlight}${action}${c_return}\"!" || return "$?"
          return 1
        fi
      fi
    elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_FEDORA}" ]; then
      if [ "${action}" = "${SHELLVNC_COMMANDS_ACTION_INSTALL}" ]; then
        command_to_execute="sudo dnf install -y ${package_name_or_link}"
      elif [ "${action}" = "${SHELLVNC_COMMANDS_ACTION_UNINSTALL}" ]; then
        command_to_execute="sudo dnf remove -y ${package_name_or_link}"
      else
        shellvnc_print_error "Unknown action \"${c_highlight}${action}${c_return}\"!" || return "$?"
        return 1
      fi
    elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_DEBIAN}" ]; then
      if [ "${action}" = "${SHELLVNC_COMMANDS_ACTION_INSTALL}" ]; then
        command_to_execute="sudo apt-get update && sudo apt-get install -y ${package_name_or_link}"
      elif [ "${action}" = "${SHELLVNC_COMMANDS_ACTION_UNINSTALL}" ]; then
        command_to_execute="sudo apt-get remove -y ${package_name_or_link}"
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
