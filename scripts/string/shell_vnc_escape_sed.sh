#!/bin/bash

# Imports
[ -z "${SHELL_VNC_PATH}" ] && { echo "Source \"shell-vnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shell_vnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
# ...
shell_vnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

# Escapes the specified text for use in the sed command.
# If you will pass the result of this command to "sed" or "grep" - please, add "-E" if you will also add it to them.
# This is because, the escaping depends on condition if extended regular expressions will be used.
#
# Usage: shell_vnc_escape_sed [-E] [text]
shell_vnc_escape_sed() {
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

shell_vnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
