#!/bin/bash

# Imports
[ -z "${SHELL_VNC_PATH}" ] && { echo "Source \"shell-vnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shell_vnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
. "./messages/shell_vnc_print_error.sh" || shell_vnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shell_vnc_print_info_increase_prefix.sh" || shell_vnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shell_vnc_print_success_decrease_prefix.sh" || shell_vnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./shell_vnc_check_requirements.sh" || shell_vnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
shell_vnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

shell_vnc_install() {
  shell_vnc_print_info_increase_prefix "Installation..." || return "$?"
  if [ "$#" -ne 1 ]; then
    shell_vnc_print_error "Usage: ${c_highlight}${FUNCNAME[0]} <server|client|both>${c_return}" || return "$?"
    return 1
  fi

  shell_vnc_check_requirements || return "$?"

  local type
  type="$1" && shift
  if [ "${type}" = "server" ] || [ "${type}" = "both" ]; then
    shell_vnc_print_info_increase_prefix "Installing server..." || return "$?"

    # TODO: Implement server installation
    # ...

    shell_vnc_print_success_decrease_prefix "Server installation: success!" || return "$?"
  fi

  if [ "${type}" = "client" ] || [ "${type}" = "both" ]; then
    shell_vnc_print_info_increase_prefix "Installing client..." || return "$?"

    # TODO: Implement client installation
    # ...

    shell_vnc_print_success_decrease_prefix "Client installation: success!" || return "$?"
  fi

  shell_vnc_print_success_decrease_prefix "Installation: success!" || return "$?"
}

shell_vnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
