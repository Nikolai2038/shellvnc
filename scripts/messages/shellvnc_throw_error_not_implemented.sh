#!/bin/bash

# Imports
[ -z "${SHELLVNC_PATH}" ] && { echo "Source \"shellvnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shellvnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
. "./_constants.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./shellvnc_print_error.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
shellvnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

shellvnc_throw_error_not_implemented() {
  if [ "$#" -ne 1 ]; then
    shellvnc_print_error "Usage: ${c_highlight}${FUNCNAME[0]} \"\${LINENO}\"${c_return}" || return "$?"
    return 1
  fi

  local line_number="$1" && shift
  shellvnc_print_error "Not implemented for \"${c_highlight}${_SHELLVNC_CURRENT_OS_NAME}${c_return}\" in file \"${c_highlight}${BASH_SOURCE[1]}${c_return}\" line \"${c_highlight}${line_number}${c_return}\"." || return "$?"
  return 1
}

shellvnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
