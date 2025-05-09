#!/bin/bash

# Imports
[ -z "${SHELLVNC_PATH}" ] && { echo "Source \"shell-vnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shellvnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
# ...
shellvnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

# "tput" but without errors if terminal does not support it.
# I use this function instead of "tput" because "tput" will just return "1" if terminal does not support some capability - without any error messages.
#
# Usage: shellvnc_tput <argument> [extra arguments...]
shellvnc_tput() {
  if [ "$#" -lt 1 ]; then
    echo "No arguments passed to \"shellvnc_tput\"!" >&2
    return 1
  fi

  local argument="$1" && shift

  # "tput" will not work with undefined "TERM" variable (for example, "ssh-copy-id" executes without that) - so we check it first.
  if [ -n "${TERM}" ]; then
    if infocmp | grep -qE "\s${argument}="; then
      tput "${argument}" "$@" || return "$?"
    elif [ "${SHELLVNC_IS_DEBUG}" = "1" ]; then
      echo "\"tput\" ignored - \"infocmp\" has no entry for \"${argument}\"!" >&2
    fi
  elif [ "${SHELLVNC_IS_DEBUG}" = "1" ]; then
    echo "\"tput\" ignored - \"TERM\" is empty!" >&2
  fi

  return 0
}

shellvnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
