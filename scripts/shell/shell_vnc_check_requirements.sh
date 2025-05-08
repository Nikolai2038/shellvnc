#!/bin/bash

# Imports
[ -z "${SHELL_VNC_PATH}" ] && { echo "Source \"shell-vnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shell_vnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
. "../messages/_constants.sh" || shell_vnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shell_vnc_print_info_increase_prefix.sh" || shell_vnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shell_vnc_print_success_decrease_prefix.sh" || shell_vnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./shell_vnc_commands_must_be_installed.sh" || shell_vnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
shell_vnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

shell_vnc_check_requirements() {
  shell_vnc_print_info_increase_prefix "Checking requirements..." || return "$?"

  shell_vnc_commands_must_be_installed which sed grep git || return "$?"

  shell_vnc_print_success_decrease_prefix "Checking requirements: success!" || return "$?"
}

shell_vnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
