#!/bin/bash

# Imports
[ -z "${SHELLVNC_PATH}" ] && { echo "Source \"shellvnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shellvnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
. "./shellvnc_terminate_ssh_tunnel.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
shellvnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

# Terminate a remote-to-local SSH port forwarding (-R).
#
# Usage: shellvnc_terminate_ssh_tunnel_R <user> <host> <port> <first_port> <second_port>
# Where:
# - "user": SSH user;
# - "host": SSH host;
# - "port": SSH port;
# - "first_port": Local port to forward;
# - "second_port": Remote port to forward.
shellvnc_terminate_ssh_tunnel_R() {
  shellvnc_terminate_ssh_tunnel -R "$@" || return "$?"
}

shellvnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
