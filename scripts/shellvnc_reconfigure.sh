#!/bin/bash

# Imports
[ -z "${SHELLVNC_PATH}" ] && { echo "Source \"shell-vnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shellvnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
. "./messages/_constants.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_print_info_increase_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_print_success_decrease_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_throw_error_not_implemented.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./string/shellvnc_cat_without_comments_and_empty_lines.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
shellvnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

shellvnc_reconfigure() {
  shellvnc_print_info_increase_prefix "Server reconfiguration..." || return "$?"

  declare -a current_displays
  # Get current VNC display numbers and split to array by words
  IFS=" " read -r -a current_displays <<< "$(sed -En 's/^:([0-9]+)=.+/\1/p' /etc/tigervnc/vncserver.users)" || return "$?"

  # Remove VNC servers for current users
  shellvnc_print_info_increase_prefix "Removing old VNC servers..." || return "$?"
  local display
  for display in "${current_displays[@]}"; do
    local service_name
    if [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_ARCH}" ] || [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_FEDORA}" ]; then
      service_name="vncserver@:${display}.service"
    elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_DEBIAN}" ]; then
      service_name="tigervncserver@:${display}.service"
    else
      shellvnc_throw_error_not_implemented "${LINENO}" || return "$?"
    fi

    if systemctl cat "${service_name}" > /dev/null 2>&1; then
      sudo systemctl disable --now "${service_name}" || return "$?"
    fi
  done
  shellvnc_print_success_decrease_prefix "Removing old VNC servers: success!" || return "$?"

  declare -a new_users
  # Get configured users and split to array by words
  IFS=" " read -r -a new_users <<< "$(shellvnc_cat_without_comments_and_empty_lines "${SHELLVNC_ENABLED_USERS_PATH}")" || return "$?"

  declare -a new_displays=()

  local displays_for_new_users=""
  local display_number=1
  for user in "${new_users[@]}"; do
    displays_for_new_users+="
:${display_number}=${user}"
    new_displays+=("${display_number}")
    display_number=$((display_number + 1))
  done

  # Specify new VNC display numbers for users
  shellvnc_print_info_increase_prefix "Updating \"${c_highlight}/etc/tigervnc/vncserver.users${c_return}\"..." || return "$?"
  cat << EOF | sudo tee /etc/tigervnc/vncserver.users > /dev/null || return "$?"
# TigerVNC user assignment
#
# This file assigns users to specific VNC display numbers.
# The syntax is <display>=<username>. E.g.:
#
# :2=andrew
# :3=lisa
${displays_for_new_users}
EOF
  shellvnc_print_success_decrease_prefix "Updating \"${c_highlight}/etc/tigervnc/vncserver.users${c_return}\": success!" || return "$?"

  # Create VNC servers for new users
  shellvnc_print_info_increase_prefix "Creating new VNC servers..." || return "$?"
  for display in "${new_displays[@]}"; do
    local service_name
    if [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_ARCH}" ] || [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_FEDORA}" ]; then
      service_name="vncserver@:${display}.service"
    elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_DEBIAN}" ]; then
      service_name="tigervncserver@:${display}.service"
    else
      shellvnc_throw_error_not_implemented "${LINENO}" || return "$?"
    fi
    sudo systemctl enable --now "${service_name}" || return "$?"
  done
  shellvnc_print_success_decrease_prefix "Creating new VNC servers: success!" || return "$?"

  shellvnc_print_success_decrease_prefix "Server reconfiguration: success!" || return "$?"
}

shellvnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
