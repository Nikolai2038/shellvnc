#!/bin/bash

# Imports
[ -z "${SHELL_VNC_PATH}" ] && { echo "Source \"shell-vnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shell_vnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
. "./_constants.sh" || shell_vnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../shell/shell_vnc_get_current_shell_name.sh" || shell_vnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
shell_vnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

export _SHELL_VNC_MESSAGE_PREFIX_LENGTH=0

# Print a colored text.
#
# Usage: shell_vnc_print_color_message [color] [text]
shell_vnc_print_color_message() {
  local main_color
  main_color="$1" && shift

  local text
  text="$1" && shift

  # Replaces the special string with the text color
  # (don't forget to escape the first color character with an additional backslash)
  if [ -n "${main_color}" ]; then
    text="$(echo "${text}" | sed -E "s/${c_return}/\\${main_color}/g")" || return "$?"
  else
    text="$(echo "${text}" | sed -E "s/${c_return}//g")" || return "$?"
  fi
  text="${main_color}${text}${c_reset}"

  local prefix=""
  if [ "${_SHELL_VNC_MESSAGE_PREFIX_LENGTH}" != "0" ]; then
    local prefix_length="$((_SHELL_VNC_MESSAGE_PREFIX_LENGTH * SHELL_VNC_MESSAGE_PREFIX_SCALE))" || return "$?"
    prefix="$(eval "printf '%.s ' {1..${prefix_length}}")" || return "$?"
  fi

  # shellcheck disable=SC2320,SC3037
  echo -e "$@" "SHELL_VNC: ${prefix}${text}" || return "$?"

  return 0
}

shell_vnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
