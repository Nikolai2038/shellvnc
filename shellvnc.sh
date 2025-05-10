#!/bin/bash

# ========================================
# Settings, which can be overridden by the user
# ========================================
export SHELLVNC_IS_DEBUG="${SHELLVNC_IS_DEBUG:-0}"
export SHELLVNC_MESSAGE_PREFIX_SCALE="${SHELLVNC_MESSAGE_PREFIX_SCALE:-2}"
export SHELLVNC_AUTO_INSTALL_PACKAGES="${SHELLVNC_AUTO_INSTALL_PACKAGES:-1}"
# ========================================

# Fail command if any of pipeline blocks fail
set -o pipefail

# Path to the directory with the "shellvnc.sh".
export SHELLVNC_PATH
SHELLVNC_PATH="$(dirname "$0")" || return "$?" 2> /dev/null || exit "$?"

# Scripts data folder
export SHELLVNC_DATA_PATH="${SHELLVNC_PATH}/data"
mkdir --parents "${SHELLVNC_DATA_PATH}" 2> /dev/null || return "$?" 2> /dev/null || exit "$?"

# File which contains installed commands for "shellvnc", which were not installed.
# This way, we can uninstall only them when "shellvnc" is uninstalled.
export SHELLVNC_INSTALLED_COMMANDS_PATH="${SHELLVNC_DATA_PATH}/installed_commands.txt"

export _SHELLVNC_CURRENT_OS_TYPE="${_SHELLVNC_CURRENT_OS_TYPE}"
export _SHELLVNC_OS_TYPE_WINDOWS="windows"
export _SHELLVNC_OS_TYPE_LINUX="linux"
export _SHELLVNC_OS_TYPE_MACOS="macos"

export _SHELLVNC_CURRENT_OS_NAME="${_SHELLVNC_CURRENT_OS_NAME}"
export _SHELLVNC_OS_NAME_WINDOWS="windows"
export _SHELLVNC_OS_NAME_TERMUX="termux"
export _SHELLVNC_OS_NAME_ARCH="arch"
export _SHELLVNC_OS_NAME_FEDORA="fedora"
export _SHELLVNC_OS_NAME_DEBIAN="debian"
export _SHELLVNC_OS_NAME_MACOS="macos"

export _SHELLVNC_CURRENT_OS_VERSION="${_SHELLVNC_CURRENT_OS_VERSION}"

# Special return code when file is already sourced
export _SHELLVNC_RETURN_CODE_WHEN_FILE_IS_ALREADY_SOURCED=238

# Check last return code.
# If it is equal to the code when file is already sourced - return 0.
# Otherwise - return the last return code.
#
# Usage: . "./some_script.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
shellvnc_return_0_if_already_sourced() {
  local return_code="$?"

  if [ "${return_code}" = "${_SHELLVNC_RETURN_CODE_WHEN_FILE_IS_ALREADY_SOURCED}" ]; then
    return 0
  fi

  return "${return_code}"
}
export -f shellvnc_return_0_if_already_sourced

# Required steps before imports.
#
# Usage: shellvnc_required_before_imports <bash_source>
shellvnc_required_before_imports() {
  if [ "$#" -ne 1 ]; then
    echo "Usage: ${FUNCNAME[0]} <bash_source>" >&2
    return 1
  fi
  local bash_source="$1" && shift

  # Check if the file is already sourced
  if [ -n "$(eval "echo \"\${__shellvnc_previous_directory_$(basename "${bash_source}" | sed 's/[^a-zA-Z0-9_]/_/g')}\"")" ]; then
    return "${_SHELLVNC_RETURN_CODE_WHEN_FILE_IS_ALREADY_SOURCED}"
  fi

  # Save current directory to return to it later
  eval "__shellvnc_previous_directory_$(basename "${bash_source}" | sed 's/[^a-zA-Z0-9_]/_/g')=${PWD}" || return "$?"

  # Go to the directory of the script
  cd "$(dirname "${bash_source}")" || return "$?"
}
export -f shellvnc_required_before_imports

# Required steps after imports.
#
# Usage: shellvnc_required_after_imports <bash_source>
shellvnc_required_after_imports() {
  if [ "$#" -ne 1 ]; then
    echo "Usage: ${FUNCNAME[0]} <bash_source>" >&2
    return 1
  fi
  local bash_source="$1" && shift

  # Return to the previous directory
  eval "cd \"\${__shellvnc_previous_directory_$(basename "${bash_source}" | sed 's/[^a-zA-Z0-9_]/_/g')}\"" || return "$?"
}
export -f shellvnc_required_after_imports

# Required steps after function declaration.
# Checks if this file is being executed or sourced.
# If this file is being executed - it will execute the function itself.
# If this file is being sourced - it will do nothing.
#
# Usage: shellvnc_required_after_function <bash_source> [args...]
shellvnc_required_after_function() {
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

  # Call the function with the same name as the file
  "${function_name}" "$@" || return "$?"

  return 0
}
export -f shellvnc_required_after_function

# Imports
shellvnc_required_before_imports "${BASH_SOURCE[0]}" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./scripts/messages/_constants.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./scripts/messages/shellvnc_print_info_increase_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./scripts/messages/shellvnc_print_error.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./scripts/messages/shellvnc_print_success_decrease_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./scripts/shellvnc_install.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./scripts/shellvnc_uninstall.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./scripts/shellvnc_update.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./scripts/shell/shellvnc_init_current_os_type_and_name.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
shellvnc_required_after_imports "${BASH_SOURCE[0]}" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"

shellvnc() {
  shellvnc_print_info_increase_prefix "Running scripts..." || return "$?"

  if [ "$#" -lt 1 ]; then
    shellvnc_print_error "Usage: ${c_highlight}${FUNCNAME[0]} <install|uninstall|update>${c_return}" || return "$?"
    return 1
  fi

  shellvnc_init_current_os_type_and_name || return "$?"

  local action="$1" && shift
  if [ "${action}" = "install" ]; then
    shellvnc_install "$@" || return "$?"
  elif [ "${action}" = "uninstall" ]; then
    shellvnc_uninstall "$@" || return "$?"
  elif [ "${action}" = "update" ]; then
    shellvnc_update "$@" || return "$?"
  else
    shellvnc_print_error "Unknown action: \"${c_highlight}${action}${c_return}\"." || return "$?"
    return 1
  fi

  shellvnc_print_success_decrease_prefix "Running scripts: success!" || return "$?"
}

shellvnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
