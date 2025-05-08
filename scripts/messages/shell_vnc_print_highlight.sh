#!/bin/bash

# Imports
[ -z "${SHELL_VNC_PATH}" ] && { echo "Source \"shell-vnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shell_vnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
. "./_constants.sh" || shell_vnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./shell_vnc_print_color_message.sh" || shell_vnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
shell_vnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

# Print highlight-colored text.
#
# Usage: shell_vnc_print_highlight [text]
shell_vnc_print_highlight() {
  shell_vnc_print_color_message "${c_highlight}" "$@" >&2 || return "$?"
  return 0
}

shell_vnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
