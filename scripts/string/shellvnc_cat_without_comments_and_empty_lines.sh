#!/bin/bash

# Imports
[ -z "${SHELLVNC_PATH}" ] && { echo "Source \"shellvnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shellvnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
. "../messages/_constants.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "../messages/shellvnc_print_error.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
shellvnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

# Prints the contents of the specified file, excluding comments and empty lines.
#
# Usage: shellvnc_cat_without_comments_and_empty_lines <file>
shellvnc_cat_without_comments_and_empty_lines() {
  if [ "$#" -ne 1 ]; then
    shellvnc_print_error "Usage: ${c_highlight}${FUNCNAME[0]} <file>${c_return}" || return "$?"
    return 1
  fi

  local file
  file="$1" && shift

  if [ ! -f "${file}" ]; then
    return 0
  fi

  grep -v '^[[:space:]]*#' "${file}" | grep -v '^[[:space:]]*$' || return "$?"
}

shellvnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
