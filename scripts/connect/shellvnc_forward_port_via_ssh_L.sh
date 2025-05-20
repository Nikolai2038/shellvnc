#!/bin/bash

# Imports
[ -z "${SHELLVNC_PATH}" ] && { echo "Source \"shellvnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shellvnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
. "./shellvnc_forward_port_via_ssh.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
shellvnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

# Forward local port to remote via SSH (-L).
#
# Usage: shellvnc_forward_port_via_ssh_L <user> <host> <port> <first_port> <second_port> <password> [<extra_ssh_args>...]
# Where:
# - "user": SSH user;
# - "host": SSH host;
# - "port": SSH port;
# - "first_port": Local port to forward;
# - "second_port": Remote port to forward;
# - "password": SSH password;
# - "extra_ssh_args": Additional SSH arguments (optional).
shellvnc_forward_port_via_ssh_L() {
  shellvnc_forward_port_via_ssh -L "$@" || return "$?"
}

shellvnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
