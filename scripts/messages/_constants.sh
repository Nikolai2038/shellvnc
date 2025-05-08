#!/bin/bash

# Imports
[ -z "${SHELL_VNC_PATH}" ] && { echo "Source \"shell-vnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shell_vnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
. "../string/shell_vnc_tput.sh" || shell_vnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
shell_vnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

# NOTE: We define empty values for Bash IDE server to find references to these variables.

# Color for usual text (and in cases when using "shell_vnc_print_color_message" function is not possible)
export c_text=""

# Color for info text
export c_info=""

# Color for successful text
export c_success=""

# Color for highlighted text
export c_highlight=""

# Color for warning text
export c_warning=""

# Color for error text
export c_error=""

# Color for border used in PS1 function - for usual user
export c_border_usual=""

# Color for border used in PS1 function - for root user
export c_border_root=""

# Reset color
export c_reset=""

# NOTE: We use "shell_vnc_tput" here to be able to define colors both for "bash" and "ksh"

# If terminal supports more that 8 default colors, we use more soft colors instead
if [ "${TERM}" = "xterm-256color" ]; then
  c_text="$(shell_vnc_tput setaf 15)" || return "$?" 2> /dev/null || exit "$?"
  c_info="$(shell_vnc_tput setaf 6)" || return "$?" 2> /dev/null || exit "$?"
  c_success="$(shell_vnc_tput setaf 2)" || return "$?" 2> /dev/null || exit "$?"
  c_highlight="$(shell_vnc_tput setaf 90)" || return "$?" 2> /dev/null || exit "$?"
  c_warning="$(shell_vnc_tput setaf 3)" || return "$?" 2> /dev/null || exit "$?"
  c_error="$(shell_vnc_tput setaf 1)" || return "$?" 2> /dev/null || exit "$?"
  c_border_usual="$(shell_vnc_tput setaf 27)" || return "$?" 2> /dev/null || exit "$?"
  c_border_root="$(shell_vnc_tput setaf 90)" || return "$?" 2> /dev/null || exit "$?"
# If terminal does not support more that 8 colors (MINGW, TTYs), we use default 8 colors
else
  c_text="$(shell_vnc_tput setaf 7)" || return "$?" 2> /dev/null || exit "$?"
  c_info="$(shell_vnc_tput setaf 6)" || return "$?" 2> /dev/null || exit "$?"
  c_success="$(shell_vnc_tput setaf 2)" || return "$?" 2> /dev/null || exit "$?"
  c_highlight="$(shell_vnc_tput setaf 5)" || return "$?" 2> /dev/null || exit "$?"
  c_warning="$(shell_vnc_tput setaf 3)" || return "$?" 2> /dev/null || exit "$?"
  c_error="$(shell_vnc_tput setaf 1)" || return "$?" 2> /dev/null || exit "$?"
  c_border_usual="$(shell_vnc_tput setaf 4)" || return "$?" 2> /dev/null || exit "$?"
  c_border_root="$(shell_vnc_tput setaf 5)" || return "$?" 2> /dev/null || exit "$?"
fi

c_reset="$(shell_vnc_tput sgr0)" || return "$?" 2> /dev/null || exit "$?"

# Color for border when printing tables, etc.
export c_border="${c_border_usual}"

# Special text that will be replaced with the previous one
export c_return='COLOR_RETURN'

shell_vnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
