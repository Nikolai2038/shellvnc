#!/bin/bash

# Imports
[ -z "${SHELLVNC_PATH}" ] && { echo "Source \"shellvnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shellvnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
# ...
shellvnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

# Escapes the specified text for use in the sed command.
# If you will pass the result of this command to "sed" or "grep" - please, add "-E" if you will also add it to them.
# This is because, the escaping depends on condition if extended regular expressions will be used.
#
# Usage: shellvnc_escape_sed [-E] [text]
shellvnc_escape_sed() {
  local text
  text="$1" && shift

  local arg
  arg="$1" && shift

  # "-E" can be as first argument or as second, so we switch them, if necessary
  if [ "${text}" = "-E" ]; then
    text="${arg}"
    arg="-E"
  fi

  if [ "${arg}" = "-E" ]; then
    # For "sed -E"
    echo "${text}" | sed -e 's/[]\/#$&*.^;|{}()[]/\\&/g' || return "$?"
  else
    # For "sed"
    echo "${text}" | sed -e 's/[]\/#$&*.^;[]/\\&/g' || return "$?"
  fi

  return 0
}

shellvnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
