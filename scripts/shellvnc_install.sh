#!/bin/bash

# Imports
[ -z "${SHELLVNC_PATH}" ] && { echo "Source \"shell-vnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shellvnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
. "./messages/_constants.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_print_error.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_print_warning.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_print_info_increase_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_print_success_decrease_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_throw_error_not_implemented.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./shell/shellvnc_check_requirements.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./shell/shellvnc_commands.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./shellvnc_reconfigure.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./string/shellvnc_generate_password.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
shellvnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

shellvnc_install() {
  shellvnc_print_info_increase_prefix "Installation..." || return "$?"

  if [ "$#" -ne 1 ]; then
    shellvnc_print_error "Usage: ${c_highlight}${FUNCNAME[0]} <server|client|both>${c_return}" || return "$?"
    return 1
  fi

  shellvnc_check_requirements || return "$?"

  local type
  type="$1" && shift
  if [ "${type}" = "server" ] || [ "${type}" = "both" ]; then
    shellvnc_print_info_increase_prefix "Installing server..." || return "$?"

    local session_type_file
    session_type_file="$(find /usr/share/xsessions -type f -name '*.desktop' | head -n 1)" || return "$?"
    if [ -z "${session_type_file}" ]; then
      shellvnc_print_error "No X11 session files found in \"${c_highlight}/usr/share/xsessions${c_return}\" directory. Please, install some window manager or desktop environment for X11 and try again." || return "$?"
      return 1
    fi

    shellvnc_commands "${SHELLVNC_COMMANDS_ACTION_INSTALL}" vncviewer pactl ssh sshpass usbip vncserver || return "$?"

    local vnc_password_for_current_user
    vnc_password_for_current_user="$(shellvnc_generate_password 8)" || return "$?"

    local session_type
    session_type="$(basename "${session_type_file}" .desktop)" || return "$?"

    shellvnc_print_info_increase_prefix "Creating config for user names..." || return "$?"
    cat << EOF | tee "${SHELLVNC_ENABLED_USERS_PATH}" > /dev/null || return "$?"
# Specify user names on each line, for which you want to enable VNC server.
#
# Format: <user_name> <vnc_password> <session_type>
# - <user_name>: only letters, digits and "_" are allowed;
# - <vnc_password>: from 6 to 8 symbols;
# - <session_type>: is the name of one of the X11 session types from the "/usr/share/xsessions" directory.
#
# Empty lines or lines, which start with "#", will be ignored.
#
# After changes, save file and run "./shellvnc.sh reconfigure".

${USER} ${vnc_password_for_current_user} ${session_type}
EOF
    shellvnc_print_success_decrease_prefix "Creating config for user names: success!" || return "$?"

    if [ -f /etc/tigervnc/vncserver-config-defaults ]; then
      shellvnc_print_info_increase_prefix "Creating backup of \"${c_highlight}/etc/tigervnc/vncserver-config-defaults${c_return}\" to \"${c_highlight}/etc/tigervnc/vncserver-config-defaults.bkp${c_return}\"..." || return "$?"
      if [ -f /etc/tigervnc/vncserver-config-defaults.bkp ]; then
        shellvnc_print_text "File \"${c_highlight}/etc/tigervnc/vncserver-config-defaults.bkp${c_return}\" already exists. Skipping backup." || return "$?"
      else
        sudo cp -T /etc/tigervnc/vncserver-config-defaults /etc/tigervnc/vncserver-config-defaults.bkp || return "$?"
      fi
      shellvnc_print_success_decrease_prefix "Creating backup of \"${c_highlight}/etc/tigervnc/vncserver-config-defaults${c_return}\" to \"${c_highlight}/etc/tigervnc/vncserver-config-defaults.bkp${c_return}\": success!" || return "$?"
    fi

    if [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_ARCH}" ] || [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_FEDORA}" ]; then
      # See "man Xvnc"
      cat << EOF | sudo tee /etc/tigervnc/vncserver-config-defaults > /dev/null || return "$?"
geometry=800x600
FrameRate=240

localhost=yes
SecurityTypes=VncAuth
PlainUsers=*
UseBlacklist=no
PamService=login
NeverShared=yes

# Increase clipboard size to 100 Mb
MaxCutText=$((1024 * 1024 * 100))
EOF
    elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_DEBIAN}" ]; then
      # See "man vncserver-config-defaults"
      cat << EOF | sudo tee /etc/tigervnc/vncserver-config-defaults > /dev/null || return "$?"
\$geometry = "800x600";
\$FrameRate = "240";

\$localhost = "yes";
\$SecurityTypes = "VncAuth";
\$PlainUsers = "*";
\$UseBlacklist = "no";
\$PamService = "login";
\$NeverShared = "yes";

# Increase clipboard size to 100 Mb
\$MaxCutText = "$((1024 * 1024 * 100))"
EOF
    else
      shellvnc_throw_error_not_implemented "${LINENO}" || return "$?"
    fi

    shellvnc_reconfigure || return "$?"

    shellvnc_print_warning "By default, VNC server will be enabled only for current user. If you want to enable it for some other user, or not for current user, please, edit \"${c_highlight}${SHELLVNC_ENABLED_USERS_PATH}${c_return}\" file and run \"${c_highlight}./shellvnc.sh reconfigure${c_return}\"." || return "$?"

    # TODO: Implement server installation
    # ...

    shellvnc_print_success_decrease_prefix "Installing server: success!" || return "$?"
  fi

  if [ "${type}" = "client" ] || [ "${type}" = "both" ]; then
    shellvnc_print_info_increase_prefix "Installing client..." || return "$?"

    shellvnc_commands "${SHELLVNC_COMMANDS_ACTION_INSTALL}" vncviewer pactl ssh sshpass usbip || return "$?"

    # TODO: Implement client installation
    # ...

    shellvnc_print_success_decrease_prefix "Installing client: success!" || return "$?"
  fi

  shellvnc_print_success_decrease_prefix "Installation: success!" || return "$?"
}

shellvnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
