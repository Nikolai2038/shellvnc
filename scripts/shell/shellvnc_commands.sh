#!/bin/bash

# Imports
[ -z "${SHELLVNC_PATH}" ] && { echo "Source \"shellvnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shellvnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
. "../messages/_constants.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shellvnc_print_info_increase_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shellvnc_print_text.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shellvnc_print_error.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shellvnc_print_warning.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shellvnc_print_success_decrease_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
shellvnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

_SHELLVNC_COMMANDS_ACTION_INSTALL="install"
_SHELLVNC_COMMANDS_ACTION_UNINSTALL="uninstall"

_SHELLVNC_WINDOWS_FILE_TYPE_PORTABLE_EXECUTABLE=0
_SHELLVNC_WINDOWS_FILE_TYPE_INSTALLER=1
_SHELLVNC_WINDOWS_FILE_TYPE_ZIP_ARCHIVE=2
_SHELLVNC_WINDOWS_FILE_TYPE_TAR_ZST_ARCHIVE=3

# Installs or removes packages for specified commands.
# Returns 0 if all the commands are installed, otherwise returns other values.
#
# Usage: shellvnc_commands <action> <command...>
shellvnc_commands() {
  if [ "$#" -lt 2 ]; then
    shellvnc_print_error "Usage: ${c_highlight}${FUNCNAME[0]} <${_SHELLVNC_COMMANDS_ACTION_INSTALL}|${_SHELLVNC_COMMANDS_ACTION_UNINSTALL}> <command...>${c_return}" || return "$?"
    return 1
  fi

  local action="$1" && shift

  local action_word_1
  local action_word_2
  if [ "${action}" = "${_SHELLVNC_COMMANDS_ACTION_INSTALL}" ]; then
    action_word_1="Installing"
    action_word_2="install"
  elif [ "${action}" = "${_SHELLVNC_COMMANDS_ACTION_UNINSTALL}" ]; then
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

    if [ "${action}" = "${_SHELLVNC_COMMANDS_ACTION_INSTALL}" ]; then
      if type "${command}" > /dev/null 2>&1; then
        shellvnc_print_text "Command \"${c_highlight}${command}${c_return}\" is installed! Skipping!" || return "$?"
        continue
      else
        shellvnc_print_text "Command \"${c_highlight}${command}${c_return}\" is not installed!" || return "$?"
      fi
    elif [ "${action}" = "${_SHELLVNC_COMMANDS_ACTION_UNINSTALL}" ]; then
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

    # (Only for Windows):
    # - 0: portable executable
    # - 1: installer
    # - 2: .zip archive
    # - 3: .tar.zst archive
    local windows_file_type=0

    # (Only for Windows, if type is 2): If the package is a zip archive
    local path_to_exe_inside_archive=""

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
        # # Direct download - very slow sometimes
        # package_name_or_link="https://sourceforge.net/projects/tigervnc/files/stable/${TIGERVNC_VERSION_FOR_WINDOWS}/vncviewer64-${TIGERVNC_VERSION_FOR_WINDOWS}.exe/download"

        # Use mirror
        package_name_or_link="https://downloads.sourceforge.net/project/tigervnc/stable/${TIGERVNC_VERSION_FOR_WINDOWS}/vncviewer64-${TIGERVNC_VERSION_FOR_WINDOWS}.exe?use_mirror=phoenixnap"

        windows_file_type="${_SHELLVNC_WINDOWS_FILE_TYPE_PORTABLE_EXECUTABLE}"
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
        # shellvnc_print_warning "When installer shows up, please remember to enable \"${c_highlight}Allow module loading${c_return}\"!" || return "$?"
        # package_name_or_link="https://github.com/pgaskin/pulseaudio-win32/releases/download/${PULSEAUDIO_VERSION_FOR_WINDOWS}/pasetup.exe"
        # windows_file_type=1

        package_name_or_link="https://github.com/pgaskin/pulseaudio-win32/releases/download/${PULSEAUDIO_VERSION_FOR_WINDOWS}/pulseaudio.zip"
        windows_file_type="${_SHELLVNC_WINDOWS_FILE_TYPE_ZIP_ARCHIVE}"
        path_to_exe_inside_archive="pulseaudio/bin/pactl.exe"
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
          for __same_command in which sed grep git ssh scp sshpass usbip openbox zstd jq; do
            if [ "${command}" = "${__same_command}" ]; then
              package_name_or_link="${__same_command}"
            fi
          done
        fi
      elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_WINDOWS}" ]; then
        if [ "${command}" = "sshpass" ]; then
          package_name_or_link="https://repo.msys2.org/msys/x86_64/sshpass-1.10-1-x86_64.pkg.tar.zst"
          windows_file_type="${_SHELLVNC_WINDOWS_FILE_TYPE_TAR_ZST_ARCHIVE}"
          path_to_exe_inside_archive="usr/bin/sshpass.exe"
        elif [ "${command}" = "zstd" ]; then
          package_name_or_link="https://github.com/facebook/zstd/releases/download/${ZSTD_VERSION_FOR_WINDOWS}/zstd-${ZSTD_VERSION_FOR_WINDOWS}-win64.zip"
          windows_file_type="${_SHELLVNC_WINDOWS_FILE_TYPE_ZIP_ARCHIVE}"
          path_to_exe_inside_archive="zstd-${ZSTD_VERSION_FOR_WINDOWS}-win64/zstd.exe"
        elif [ "${command}" = "jq" ]; then
          package_name_or_link="https://github.com/jqlang/jq/releases/latest/download/jq-win64.exe"
          windows_file_type="${_SHELLVNC_WINDOWS_FILE_TYPE_PORTABLE_EXECUTABLE}"
        elif [ "${command}" = "usbip" ]; then
          package_name_or_link="https://github.com/cezanne/usbip-win/releases/download/v${USBIP_VERSION_FOR_WINDOWS}/usbip-win-${USBIP_VERSION_FOR_WINDOWS}.zip"
          windows_file_type="${_SHELLVNC_WINDOWS_FILE_TYPE_ZIP_ARCHIVE}"
          path_to_exe_inside_archive="usbip.exe"
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
      local executable_path link_path file_name

      executable_path="/usr/bin/${command}.exe" || return "$?"
      link_path="/usr/bin/${command}" || return "$?"

      if [ "${action}" = "${_SHELLVNC_COMMANDS_ACTION_INSTALL}" ]; then
        if [ "${windows_file_type}" = "${_SHELLVNC_WINDOWS_FILE_TYPE_PORTABLE_EXECUTABLE}" ]; then
          shellvnc_print_text "Installation type: \"${c_highlight}Portable executable${c_return}\"!" || return "$?"
          file_name="$(basename "${executable_path}")" || return "$?"

          # Download executable file (symlink will be visible automatically by Git Bash)
          command_to_execute="sudo curl --fail -L -o \"${executable_path}\" \"${package_name_or_link}\""
        elif [ "${windows_file_type}" = "${_SHELLVNC_WINDOWS_FILE_TYPE_INSTALLER}" ]; then
          shellvnc_print_text "Installation type: \"${c_highlight}Installer${c_return}\"!" || return "$?"
          file_name="$(basename "${executable_path}")" || return "$?"

          # 1. Download installer
          # 2. Run installer
          # 3. Remove installer
          command_to_execute="sudo curl --fail -L -o \"${file_name}\" \"${package_name_or_link}\" && ./${file_name} || { error_code=\"\$?\" && rm \"${file_name}\"; shellvnc_print_error \"Error occurred while trying to install!\" || return \"\$?\"; return \"\${error_code}\"; }; rm \"${file_name}\"" || return "$?"
        elif [ "${windows_file_type}" = "${_SHELLVNC_WINDOWS_FILE_TYPE_ZIP_ARCHIVE}" ]; then
          shellvnc_print_text "Installation type: \"${c_highlight}.zip archive${c_return}\"!" || return "$?"
          file_name="$(basename "${package_name_or_link}")" || return "$?"

          # 1. Download zip archive
          # 2. Unzip it to /usr/lib/${command}
          # 3. Create symlink so checks if this command is installed will work now
          # 4. Remove zip archive
          # NOTE: We must escape ">" here, because it is used inside the call function.
          command_to_execute="sudo curl --fail -L -o \"${file_name}\" \"${package_name_or_link}\" && sudo unzip -o \"${file_name}\" -d \"/usr/lib/${command}\" && sudo echo \"\\\"/usr/lib/${command}/${path_to_exe_inside_archive}\\\" \\\"\\\$@\\\"\" \">\" \"${link_path}\" && sudo chmod +x \"${link_path}\" || { error_code=\"\$?\" && rm \"${file_name}\"; shellvnc_print_error \"Error occurred while trying to install!\" || return \"\$?\"; return \"\${error_code}\"; }; rm \"${file_name}\"" || return "$?"
        elif [ "${windows_file_type}" = "${_SHELLVNC_WINDOWS_FILE_TYPE_TAR_ZST_ARCHIVE}" ]; then
          # Install required "zstd" command to uncompress the archive
          shellvnc_commands "${_SHELLVNC_COMMANDS_ACTION_INSTALL}" zstd || return "$?"

          shellvnc_print_text "Installation type: \"${c_highlight}.tar.zst archive${c_return}\"!" || return "$?"
          file_name="$(basename "${package_name_or_link}")" || return "$?"

          # 1. Download tar.zst archive
          # 2. Unzip it to /usr/lib/${command}
          # 3. Create symlink so checks if this command is installed will work now
          # 4. Remove tar.zst archive
          command_to_execute="sudo curl --fail -L -o \"${file_name}\" \"${package_name_or_link}\" && sudo mkdir --parents \"/usr/lib/${command}\" && sudo tar -xvf \"${file_name}\" -C \"/usr/lib/${command}\" && sudo echo \"\\\"/usr/lib/${command}/${path_to_exe_inside_archive}\\\" \\\"\\\$@\\\"\" \">\" \"${link_path}\" && sudo chmod +x \"${link_path}\" || { error_code=\"\$?\" && rm \"${file_name}\"; shellvnc_print_error \"Error occurred while trying to install!\" || return \"\$?\"; return \"\${error_code}\"; }; rm \"${file_name}\"" || return "$?"
        else
          shellvnc_print_error "Unknown file type \"${c_highlight}${windows_file_type}${c_return}\"!" || return "$?"
          return 1
        fi
      elif [ "${action}" = "${_SHELLVNC_COMMANDS_ACTION_UNINSTALL}" ]; then
        if [ "${windows_file_type}" = "0" ]; then
          shellvnc_print_text "Uninstallation type: \"${c_highlight}Portable executable${c_return}\"!" || return "$?"

          # Delete executable file
          command_to_execute="sudo rm -rf \"${executable_path}\"" || return "$?"
        elif [ "${windows_file_type}" = "1" ]; then
          shellvnc_print_text "Uninstallation type: \"${c_highlight}Installer${c_return}\"!" || return "$?"

          shellvnc_print_error "Uninstalling \"${c_highlight}${command}${c_return}\" is not implemented for \"${c_highlight}${_SHELLVNC_CURRENT_OS_NAME}${c_return}\"!" || return "$?"
          return 1
        elif [ "${windows_file_type}" = "2" ]; then
          shellvnc_print_text "Uninstallation type: \"${c_highlight}.zip archive${c_return}\"!" || return "$?"

          # 1. Delete symlink
          # 2. Delete files
          command_to_execute="unlink \"${link_path}\" && sudo rm -rf \"/usr/lib/${command}\"" || return "$?"
        elif [ "${windows_file_type}" = "3" ]; then
          shellvnc_print_text "Uninstallation type: \"${c_highlight}.tar.zst archive${c_return}\"!" || return "$?"

          # 1. Delete symlink
          # 2. Delete files
          command_to_execute="unlink \"${link_path}\" && sudo rm -rf \"/usr/lib/${command}\"" || return "$?"
        else
          shellvnc_print_error "Unknown file type \"${c_highlight}${windows_file_type}${c_return}\"!" || return "$?"
          return 1
        fi
      else
        shellvnc_print_error "Unknown action \"${c_highlight}${action}${c_return}\"!" || return "$?"
        return 1
      fi
    elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_TERMUX}" ]; then
      if [ "${action}" = "${_SHELLVNC_COMMANDS_ACTION_INSTALL}" ]; then
        command_to_execute="pkg update && pkg install -y ${package_name_or_link}"
      elif [ "${action}" = "${_SHELLVNC_COMMANDS_ACTION_UNINSTALL}" ]; then
        command_to_execute="pkg remove -y ${package_name_or_link}"
      else
        shellvnc_print_error "Unknown action \"${c_highlight}${action}${c_return}\"!" || return "$?"
        return 1
      fi
    elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_ARCH}" ]; then
      if [ "${is_aur}" = "1" ]; then
        if [ "${action}" = "${_SHELLVNC_COMMANDS_ACTION_INSTALL}" ]; then
          command_to_execute="yay --sync --refresh --needed --noconfirm ${package_name_or_link}"
        elif [ "${action}" = "${_SHELLVNC_COMMANDS_ACTION_UNINSTALL}" ]; then
          command_to_execute="yay -Runs --noconfirm ${package_name_or_link}"
        else
          shellvnc_print_error "Unknown action \"${c_highlight}${action}${c_return}\"!" || return "$?"
          return 1
        fi
      else
        if [ "${action}" = "${_SHELLVNC_COMMANDS_ACTION_INSTALL}" ]; then
          command_to_execute="sudo pacman --sync --refresh --needed --noconfirm ${package_name_or_link}"
        elif [ "${action}" = "${_SHELLVNC_COMMANDS_ACTION_UNINSTALL}" ]; then
          command_to_execute="sudo pacman -Runs --noconfirm ${package_name_or_link}"
        else
          shellvnc_print_error "Unknown action \"${c_highlight}${action}${c_return}\"!" || return "$?"
          return 1
        fi
      fi
    elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_FEDORA}" ]; then
      if [ "${action}" = "${_SHELLVNC_COMMANDS_ACTION_INSTALL}" ]; then
        command_to_execute="sudo dnf install -y ${package_name_or_link}"
      elif [ "${action}" = "${_SHELLVNC_COMMANDS_ACTION_UNINSTALL}" ]; then
        command_to_execute="sudo dnf remove -y ${package_name_or_link}"
      else
        shellvnc_print_error "Unknown action \"${c_highlight}${action}${c_return}\"!" || return "$?"
        return 1
      fi
    elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_DEBIAN}" ]; then
      if [ "${action}" = "${_SHELLVNC_COMMANDS_ACTION_INSTALL}" ]; then
        command_to_execute="sudo apt-get update && sudo apt-get install -y ${package_name_or_link}"
      elif [ "${action}" = "${_SHELLVNC_COMMANDS_ACTION_UNINSTALL}" ]; then
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
    # Save information about installed command to be able to remove it when uninstalling
    # ========================================
    # shellcheck disable=SC2320
    echo "${command}" >> "${SHELLVNC_INSTALLED_COMMANDS_PATH}" || return "$?"

    # Remove duplicated entries
    local current_content
    current_content="$(cat "${SHELLVNC_INSTALLED_COMMANDS_PATH}")" || return "$?"
    current_content="$(echo "${current_content}" | sort -u)" || return "$?"
    echo "${current_content}" > "${SHELLVNC_INSTALLED_COMMANDS_PATH}" || return "$?"
    shellvnc_print_text "Command \"${c_highlight}${command}${c_return}\" is added to \"${c_highlight}${SHELLVNC_INSTALLED_COMMANDS_PATH}${c_return}\"!" || return "$?"
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
