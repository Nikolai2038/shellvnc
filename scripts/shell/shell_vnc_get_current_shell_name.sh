#!/bin/bash

# Imports
[ -z "${SHELL_VNC_PATH}" ] && { echo "Source \"shell-vnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shell_vnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
# ...
shell_vnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

_SHELL_VNC_CURRENT_SHELL_NAME_BASH="bash"
_SHELL_VNC_CURRENT_SHELL_NAME_ZSH="zsh"
_SHELL_VNC_CURRENT_SHELL_NAME_KSH="ksh"
_SHELL_VNC_CURRENT_SHELL_NAME_TCSH="tcsh"
_SHELL_VNC_CURRENT_SHELL_NAME_DASH="dash"
_SHELL_VNC_CURRENT_SHELL_NAME_SH="sh"

# TODO: Implement.
_SHELL_VNC_CURRENT_SHELL_NAME_FISH="fish"

# Prints name of the current shell.
#
# Usage: shell_vnc_get_current_shell_name
shell_vnc_get_current_shell_name() {
  if [ -n "${BASH}" ]; then
    echo "${_SHELL_VNC_CURRENT_SHELL_NAME_BASH}"
  elif [ -n "${ZSH_NAME}" ]; then
    echo "${_SHELL_VNC_CURRENT_SHELL_NAME_ZSH}"
  elif [ -n "${KSH_VERSION}" ]; then
    echo "${_SHELL_VNC_CURRENT_SHELL_NAME_KSH}"
  elif [ -n "${shell}" ]; then
    echo "${_SHELL_VNC_CURRENT_SHELL_NAME_TCSH}"
  else
    echo "${_SHELL_VNC_CURRENT_SHELL_NAME_SH}"
  fi
  return 0
}

shell_vnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
