#!/bin/bash

# Imports
[ -z "${SHELLVNC_PATH}" ] && { echo "Source \"shellvnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shellvnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
. "./messages/_constants.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_print_warning.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_print_info_increase_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_print_success_decrease_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_throw_error_not_implemented.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./string/shellvnc_cat_without_comments_and_empty_lines.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
shellvnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

shellvnc_reconfigure() {
  shellvnc_print_info_increase_prefix "Server reconfiguration..." || return "$?"

  if [ -f /etc/tigervnc/vncserver.users ]; then
    declare -a current_displays
    # Get current VNC display numbers and split to array by words
    IFS=" " read -r -a current_displays <<< "$(sed -En 's/^:([0-9]+)=(.+)/\1/p' /etc/tigervnc/vncserver.users)" || return "$?"

    declare -a current_user_names
    # Get current VNC user names and split to array by words
    IFS=" " read -r -a current_user_names <<< "$(sed -En 's/^:([0-9]+)=(.+)/\2/p' /etc/tigervnc/vncserver.users)" || return "$?"

    local user
    for user in "${current_user_names[@]}"; do
      local user_home_directory
      user_home_directory="$(getent passwd "${user}" | cut -d: -f6)" || return "$?"

      sudo su - "${user}" sh -c "if [ -f \"${user_home_directory}/${SHELLVNC_PATH_TO_FILE_WITH_USER_PORT}\" ]; then rm \"${user_home_directory}/${SHELLVNC_PATH_TO_FILE_WITH_USER_PORT}\"; fi" || return "$?"
    done

    # Remove VNC servers for current users
    shellvnc_print_info_increase_prefix "Removing old VNC servers..." || return "$?"
    local display
    for display in "${current_displays[@]}"; do
      local service_name
      if [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_ARCH}" ] || [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_FEDORA}" ]; then
        service_name="vncserver@:${display}.service"
      elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_DEBIAN}" ] || [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_UBUNTU}" ]; then
        service_name="tigervncserver@:${display}.service"
      else
        shellvnc_throw_error_not_implemented "${LINENO}" || return "$?"
      fi

      if systemctl cat "${service_name}" > /dev/null 2>&1; then
        sudo systemctl disable --now "${service_name}" || return "$?"
      fi
    done
    shellvnc_print_success_decrease_prefix "Removing old VNC servers: success!" || return "$?"
  fi

  if [ ! -f "${SHELLVNC_ENABLED_USERS_PATH}" ]; then
    shellvnc_print_warning "No users configured in \"${c_highlight}${SHELLVNC_ENABLED_USERS_PATH}${c_return}\" file - no VNC servers will be created." || return "$?"
    shellvnc_print_success_decrease_prefix "Server reconfiguration: success!" || return "$?"
    return 0
  fi

  declare -a new_user_names
  declare -a new_user_passwords
  declare -a new_user_session_types
  # Get configured users and split to array by words
  IFS=" " read -r -a new_user_names <<< "$(sed -En 's/^([a-zA-Z_][a-zA-Z_0-9]*) (.+) (.+)/\1/p' "${SHELLVNC_ENABLED_USERS_PATH}")" || return "$?"
  IFS=" " read -r -a new_user_passwords <<< "$(sed -En 's/^([a-zA-Z_][a-zA-Z_0-9]*) (.+) (.+)/\2/p' "${SHELLVNC_ENABLED_USERS_PATH}")" || return "$?"
  IFS=" " read -r -a new_user_session_types <<< "$(sed -En 's/^([a-zA-Z_][a-zA-Z_0-9]*) (.+) (.+)/\3/p' "${SHELLVNC_ENABLED_USERS_PATH}")" || return "$?"
  local new_users_count="${#new_user_names[@]}"

  local displays_for_new_user_names=""
  declare -a new_displays=()

  local config_path_from_user_home_directory
  if [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_ARCH}" ] || [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_FEDORA}" ]; then
    config_path_from_user_home_directory=".config/tigervnc/config"
  elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_DEBIAN}" ] || [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_UBUNTU}" ]; then
    config_path_from_user_home_directory=".vnc/config"
  else
    shellvnc_throw_error_not_implemented "${LINENO}" || return "$?"
  fi

  local new_user_id
  for ((new_user_id = 0; new_user_id < new_users_count; new_user_id++)); do
    local display_number="$((new_user_id + 1))"
    local user="${new_user_names[i]}"
    local password="${new_user_passwords[i]}"
    local session_type="${new_user_session_types[i]}"
    if [ -z "${user}" ] || [ -z "${password}" ]; then
      shellvnc_print_error "User name or password is empty!" || return "$?"
      return 1
    fi

    new_displays+=("${display_number}")
    displays_for_new_user_names+="
:${display_number}=${user}"

    shellvnc_print_info_increase_prefix "Creating VNC password for user \"${c_highlight}${user}${c_return}\"..." || return "$?"
    sudo su - "${user}" sh -c "echo -en '${password}\n${password}\nn\n' | vncpasswd" > /dev/null || return "$?"
    shellvnc_print_success_decrease_prefix "Creating VNC password for user \"${c_highlight}${user}${c_return}\": success!" || return "$?"

    local user_home_directory
    user_home_directory="$(getent passwd "${user}" | cut -d: -f6)" || return "$?"
    sudo su - "${user}" sh -c "mkdir --parents \"${user_home_directory}/.vnc\"" > /dev/null || return "$?"
    cat << EOF | tee "${user_home_directory}/${config_path_from_user_home_directory}" > /dev/null || return "$?"
session=${session_type}
EOF

    local vnc_port
    vnc_port="$((5900 + display_number))" || return "$?"
    sudo su - "${user}" sh -c "echo \"${vnc_port}\" > \"${user_home_directory}/${SHELLVNC_PATH_TO_FILE_WITH_USER_PORT}\"" || return "$?"
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
${displays_for_new_user_names}
EOF
  shellvnc_print_success_decrease_prefix "Updating \"${c_highlight}/etc/tigervnc/vncserver.users${c_return}\": success!" || return "$?"

  # Create VNC servers for new users
  shellvnc_print_info_increase_prefix "Creating new VNC servers..." || return "$?"
  for display in "${new_displays[@]}"; do
    local service_name
    if [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_ARCH}" ] || [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_FEDORA}" ]; then
      service_name="vncserver@:${display}.service"
    elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_DEBIAN}" ] || [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_UBUNTU}" ]; then
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
