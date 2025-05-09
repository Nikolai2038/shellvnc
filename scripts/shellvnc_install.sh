#!/bin/bash

# Imports
[ -z "${SHELLVNC_PATH}" ] && { echo "Source \"shell-vnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shellvnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
. "./messages/_constants.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_print_error.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_print_info_increase_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_print_success_decrease_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./shell/shellvnc_check_requirements.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./shell/shellvnc_commands.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
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

    shellvnc_commands "${SHELLVNC_COMMANDS_ACTION_INSTALL}" vncviewer || return "$?"

    # TODO: Implement server installation
    # ...

    shellvnc_print_success_decrease_prefix "Installing server: success!" || return "$?"
  fi

  if [ "${type}" = "client" ] || [ "${type}" = "both" ]; then
    shellvnc_print_info_increase_prefix "Installing client..." || return "$?"

    shellvnc_commands "${SHELLVNC_COMMANDS_ACTION_INSTALL}" vncviewer || return "$?"

    # TODO: Implement client installation
    # ...

    shellvnc_print_success_decrease_prefix "Installing client: success!" || return "$?"
  fi

  shellvnc_print_success_decrease_prefix "Installation: success!" || return "$?"
}

shellvnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
