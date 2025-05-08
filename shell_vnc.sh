#!/bin/bash

# ========================================
# Settings, which can be overridden by the user
# ========================================
export SHELL_VNC_IS_DEBUG="${SHELL_VNC_IS_DEBUG:-0}"
export SHELL_VNC_MESSAGE_PREFIX_SCALE="${SHELL_VNC_MESSAGE_PREFIX_SCALE:-2}"
# ========================================

# Fail command if any of pipeline blocks fail
set -o pipefail

export SHELL_VNC_PATH
SHELL_VNC_PATH="$(dirname "$0")" || return "$?" 2> /dev/null || exit "$?"

export _SHELL_VNC_RETURN_CODE_WHEN_FILE_IS_ALREADY_SOURCED=238

shell_vnc_return_0_if_already_sourced() {
  local return_code="$?"

  if [ "${return_code}" = "${_SHELL_VNC_RETURN_CODE_WHEN_FILE_IS_ALREADY_SOURCED}" ]; then
    return 0
  fi

  return "${return_code}"
}
export -f shell_vnc_return_0_if_already_sourced

shell_vnc_required_before_imports() {
  if [ "$#" -ne 1 ]; then
    echo "Usage: ${FUNCNAME[0]} <bash_source>" >&2
    return 1
  fi
  local bash_source="$1" && shift

  if [ -n "$(eval "echo \"\${__shell_vnc_previous_directory_$(basename "${bash_source}" | sed 's/[^a-zA-Z0-9_]/_/g')}\"")" ]; then
    return "${_SHELL_VNC_RETURN_CODE_WHEN_FILE_IS_ALREADY_SOURCED}"
  fi

  eval "__shell_vnc_previous_directory_$(basename "${bash_source}" | sed 's/[^a-zA-Z0-9_]/_/g')=${PWD}" || return "$?"
  cd "$(dirname "${bash_source}")" || return "$?"
}
export -f shell_vnc_required_before_imports

shell_vnc_required_after_imports() {
  if [ "$#" -ne 1 ]; then
    echo "Usage: ${FUNCNAME[0]} <bash_source>" >&2
    return 1
  fi
  local bash_source="$1" && shift

  eval "cd \"\${__shell_vnc_previous_directory_$(basename "${bash_source}" | sed 's/[^a-zA-Z0-9_]/_/g')}\"" || return "$?"
}
export -f shell_vnc_required_after_imports

# Required steps after function declaration.
# Checks if this file is being executed or sourced.
# If this file is being executed - it will execute the function itself.
# If this file is being sourced - it will do nothing.
#
# Usage: shell_vnc_required_after_function
shell_vnc_required_after_function() {
  if [ "$#" -lt 1 ]; then
    echo "Usage: ${FUNCNAME[0]} <bash_source>" >&2
    return 1
  fi
  local bash_source="$1" && shift

  # If file is being sourced - we do nothing.
  # NOTE: Not all files will have function with the same name - for example, constants and aliases.
  #       But the situation, where we want to execute file without function in it is not considered.
  if [ "$(basename "$0")" != "$(basename "${bash_source}")" ]; then
    return 0
  fi

  if [ ! -f "${bash_source}" ]; then
    echo "File \"${bash_source}\" does not exist." >&2
    return 1
  fi

  local function_name
  function_name="$(basename "${bash_source}" .sh)" || return "$?"

  "${function_name}" "$@" || return "$?"

  return 0
}
export -f shell_vnc_required_after_function

# Imports
shell_vnc_required_before_imports "${BASH_SOURCE[0]}" || shell_vnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./scripts/messages/_constants.sh" || shell_vnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./scripts/messages/shell_vnc_print_info.sh" || shell_vnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./scripts/messages/shell_vnc_print_error.sh" || shell_vnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./scripts/shell_vnc_install.sh" || shell_vnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./scripts/shell_vnc_uninstall.sh" || shell_vnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./scripts/shell_vnc_update.sh" || shell_vnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
shell_vnc_required_after_imports "${BASH_SOURCE[0]}" || shell_vnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"

shell_vnc() {
  if [ "$#" -lt 1 ]; then
    shell_vnc_print_error "Usage: ${c_highlight}${FUNCNAME[0]} <install|uninstall|update>${c_return}" || return "$?"
    return 1
  fi

  local action="$1" && shift

  if [ "${action}" = "install" ]; then
    shell_vnc_install "$@" || return "$?"
  elif [ "${action}" = "uninstall" ]; then
    shell_vnc_uninstall "$@" || return "$?"
  elif [ "${action}" = "update" ]; then
    shell_vnc_update "$@" || return "$?"
  else
    shell_vnc_print_error "Unknown action: \"${c_highlight}${action}${c_return}\"." || return "$?"
    return 1
  fi
}

shell_vnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
