#!/bin/bash

# Imports
[ -z "${SHELLVNC_PATH}" ] && { echo "Source \"shell-vnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
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

    if [ -f "${SHELLVNC_ENABLED_USERS_PATH}" ]; then
      shellvnc_print_info_increase_prefix "Clearing VNC users..." || return "$?"
      rm "${SHELLVNC_ENABLED_USERS_PATH}" || return "$?"
      shellvnc_print_success_decrease_prefix "Clearing VNC users: success!" || return "$?"
      shellvnc_reconfigure || return "$?"
    fi

    # TODO: Implement server uninstallation
    # ...

    shellvnc_print_success_decrease_prefix "Uninstalling server: success!" || return "$?"
  fi

  if [ "${type}" = "client" ] || [ "${type}" = "both" ]; then
    shellvnc_print_info_increase_prefix "Uninstalling client..." || return "$?"

    # TODO: Implement client uninstallation
    # ...

    shellvnc_print_success_decrease_prefix "Uninstalling client: success!" || return "$?"
  fi

  shellvnc_print_info_increase_prefix "Uninstalling installed commands..." || return "$?"
  if [ -f "${SHELLVNC_INSTALLED_COMMANDS_PATH}" ]; then
    declare -a commands_to_uninstall=()
    # shellcheck disable=SC2207
    commands_to_uninstall=($(cat "${SHELLVNC_INSTALLED_COMMANDS_PATH}")) || return "$?"

    shellvnc_commands "${SHELLVNC_COMMANDS_ACTION_UNINSTALL}" "${commands_to_uninstall[@]}" || return "$?"
    rm "${SHELLVNC_INSTALLED_COMMANDS_PATH}" || return "$?"
  else
    shellvnc_print_text "All commands were already installed before \"${c_highlight}shellvnc${c_return}\" installation - none will be uninstalled." || return "$?"
  fi
  shellvnc_print_success_decrease_prefix "Uninstalling installed commands: success!" || return "$?"

  shellvnc_print_success_decrease_prefix "Uninstallation: success!" || return "$?"
}

shellvnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
