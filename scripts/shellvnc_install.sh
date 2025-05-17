#!/bin/bash

# Imports
[ -z "${SHELLVNC_PATH}" ] && { echo "Source \"shellvnc.sh\" first!" >&2 && return 1 2> /dev/null || exit 1; }
shellvnc_required_before_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"
. "./messages/_constants.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_print_error.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_print_warning.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_print_info_increase_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_print_success_decrease_prefix.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./messages/shellvnc_throw_error_not_implemented.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./shell/shellvnc_check_requirements.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./shell/shellvnc_commands.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./shellvnc_reconfigure.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
. "./string/shellvnc_generate_password.sh" || shellvnc_return_0_if_already_sourced || return "$?" 2> /dev/null || exit "$?"
shellvnc_required_after_imports "${BASH_SOURCE[0]}" || return "$?" 2> /dev/null || exit "$?"

shellvnc_install() {
  shellvnc_print_info_increase_prefix "Installation..." || return "$?"

  if [ "$#" -ne 1 ]; then
    shellvnc_print_error "Usage: ${c_highlight}${FUNCNAME[0]} <server|client|both>${c_return}" || return "$?"
    return 1
  fi

  shellvnc_check_requirements || return "$?"

  local type
  type="$1" && shift
  if [ "${type}" = "server" ] || [ "${type}" = "both" ]; then
    shellvnc_print_info_increase_prefix "Installing server..." || return "$?"

    local session_type_file
    session_type_file="$(find /usr/share/xsessions -type f -name '*.desktop' | head -n 1)" || return "$?"
    if [ -z "${session_type_file}" ]; then
      shellvnc_print_error "No X11 session files found in \"${c_highlight}/usr/share/xsessions${c_return}\" directory. Please, install some window manager or desktop environment for X11 and try again." || return "$?"
      return 1
    fi

    shellvnc_commands "${_SHELLVNC_COMMANDS_ACTION_INSTALL}" vncviewer pactl ssh sshpass usbip vncserver openbox || return "$?"

    local vnc_password_for_current_user
    vnc_password_for_current_user="$(shellvnc_generate_password 8)" || return "$?"

    local session_type
    session_type="$(basename "${session_type_file}" .desktop)" || return "$?"

    shellvnc_print_info_increase_prefix "Creating config for user names..." || return "$?"
    cat << EOF | tee "${SHELLVNC_ENABLED_USERS_PATH}" > /dev/null || return "$?"
# Specify user names on each line, for which you want to enable VNC server.
#
# Format: <user_name> <vnc_password> <session_type>
# - <user_name>: only letters, digits and "_" are allowed;
# - <vnc_password>: from 6 to 8 symbols;
# - <session_type>: is the name of one of the X11 session types from the "/usr/share/xsessions" directory.
#
# Empty lines or lines, which start with "#", will be ignored.
#
# After changes, save file and run "./shellvnc.sh reconfigure".

${USER} ${vnc_password_for_current_user} ${session_type}
EOF
    shellvnc_print_success_decrease_prefix "Creating config for user names: success!" || return "$?"

    if [ -f /etc/tigervnc/vncserver-config-defaults ]; then
      shellvnc_print_info_increase_prefix "Creating backup of \"${c_highlight}/etc/tigervnc/vncserver-config-defaults${c_return}\" to \"${c_highlight}/etc/tigervnc/vncserver-config-defaults.bkp${c_return}\"..." || return "$?"
      if [ -f /etc/tigervnc/vncserver-config-defaults.bkp ]; then
        shellvnc_print_text "File \"${c_highlight}/etc/tigervnc/vncserver-config-defaults.bkp${c_return}\" already exists. Skipping backup." || return "$?"
      else
        sudo cp -T /etc/tigervnc/vncserver-config-defaults /etc/tigervnc/vncserver-config-defaults.bkp || return "$?"
      fi
      shellvnc_print_success_decrease_prefix "Creating backup of \"${c_highlight}/etc/tigervnc/vncserver-config-defaults${c_return}\" to \"${c_highlight}/etc/tigervnc/vncserver-config-defaults.bkp${c_return}\": success!" || return "$?"
    fi

    if [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_ARCH}" ] || [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_FEDORA}" ]; then
      # See "man Xvnc"
      cat << EOF | sudo tee /etc/tigervnc/vncserver-config-defaults > /dev/null || return "$?"
geometry=800x600
FrameRate=240

localhost=yes
SecurityTypes=VncAuth
NeverShared=yes

# Perform pixel comparison on framebuffer to reduce unnecessary updates. Can be either 0 (off), 1 (always) or 2 (auto). Default is 2.
CompareFB=1

AllowOverride=desktop,AcceptPointerEvents,SendCutText,AcceptCutText,SendPrimary,SetPrimary,FrameRate

# Increase clipboard size to 100 Mb
MaxCutText=$((1024 * 1024 * 100))
EOF
    elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_DEBIAN}" ] || [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_UBUNTU}" ]; then
      # See "man vncserver-config-defaults"
      cat << EOF | sudo tee /etc/tigervnc/vncserver-config-defaults > /dev/null || return "$?"
\$geometry = "800x600";
\$FrameRate = "240";

\$localhost = "yes";
\$SecurityTypes = "VncAuth";
\$NeverShared = "yes";

# Perform pixel comparison on framebuffer to reduce unnecessary updates. Can be either 0 (off), 1 (always) or 2 (auto). Default is 2.
\$CompareFB = "1";

\$AllowOverride = "desktop,AcceptPointerEvents,SendCutText,AcceptCutText,SendPrimary,SetPrimary,FrameRate";

# Increase clipboard size to 100 Mb
\$MaxCutText = "$((1024 * 1024 * 100))";
EOF
    else
      shellvnc_throw_error_not_implemented "${LINENO}" || return "$?"
    fi

    local service_name
    if [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_ARCH}" ] || [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_FEDORA}" ]; then
      service_name="vncserver@:.service"
    elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_DEBIAN}" ] || [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_UBUNTU}" ]; then
      service_name="tigervncserver@:.service"
    else
      shellvnc_throw_error_not_implemented "${LINENO}" || return "$?"
    fi

    # To make VNC sessions restart automatically after ending (when user logouts)
    sudo mkdir "/etc/systemd/system/${service_name}.d" || return "$?"
    echo '[Service]
Restart=on-success
RestartSec=3' | sudo tee "/etc/systemd/system/${service_name}.d/override.conf" || return "$?"
    sudo systemctl daemon-reload || return "$?"

    shellvnc_reconfigure || return "$?"
    shellvnc_print_warning "By default, VNC server will be enabled only for current user. If you want to enable it for some other user, or not for current user, please, edit \"${c_highlight}${SHELLVNC_ENABLED_USERS_PATH}${c_return}\" file and run \"${c_highlight}./shellvnc.sh reconfigure${c_return}\"." || return "$?"

    # ========================================
    # PolKit rules
    # ========================================
    shellvnc_print_info_increase_prefix "Adding PolKit rules..." || return "$?"

    # Allow administrators to reboot, power off, etc., including when other users may still be logged in
    cat << EOF | sudo tee /etc/polkit-1/rules.d/99-shellvnc-allow-admins-to-reboot.rules > /dev/null || return "$?"
polkit.addRule(function(action, subject) {
  // Allow administrators to reboot, power off, etc., including when other users may still be logged in
  if (action.id.startsWith("org.freedesktop.login1.") && (subject.isInGroup("sudo") || subject.isInGroup("wheel"))) {
    return polkit.Result.YES;
  }
});
EOF

    # Allow administrators to configure NetworkManager
    cat << EOF | sudo tee /etc/polkit-1/rules.d/99-shellvnc-allow-admins-to-change-network.rules > /dev/null || return "$?"
polkit.addRule(function(action, subject) {
  // Allow administrators to configure NetworkManager
  if (action.id.startsWith("org.freedesktop.NetworkManager.") && (subject.isInGroup("sudo") || subject.isInGroup("wheel"))) {
    return polkit.Result.YES;
  }
});
EOF

    shellvnc_print_success_decrease_prefix "Adding PolKit rules: success!" || return "$?"
    # ========================================

    # ========================================
    # Desktop entry
    # ========================================
    shellvnc_print_info_increase_prefix "Creating desktop entry..." || return "$?"

    # Path to file in the target system, where VNC password is stored
    local path_to_vnc_password=""
    if [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_ARCH}" ] || [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_FEDORA}" ]; then
      path_to_vnc_password=".config/tigervnc/passwd"
    elif [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_DEBIAN}" ] || [ "${_SHELLVNC_CURRENT_OS_NAME}" = "${_SHELLVNC_OS_NAME_UBUNTU}" ]; then
      path_to_vnc_password=".vnc/passwd"
    else
      shellvnc_throw_error_not_implemented "${LINENO}" || return "$?"
    fi

    if [ -f /etc/xdg/openbox/autostart ]; then
      if [ -f /etc/xdg/openbox/autostart.bkp ]; then
        shellvnc_print_text "File \"${c_highlight}/etc/xdg/openbox/autostart.bkp${c_return}\" already exists. Skipping backup." || return "$?"
      else
        sudo cp -T /etc/xdg/openbox/autostart /etc/xdg/openbox/autostart.bkp || return "$?"
      fi
    fi

    # This code must be in Bourne Shell syntax on Debian-based systems.
    cat << EOF | sudo tee /etc/xdg/openbox/autostart > /dev/null || return "$?"
# Unload PulseAudio if previously loaded when connected remotely
pactl unload-module module-tunnel-sink || true

vnc_args='
  -PasswordFile="${path_to_vnc_password}"

  # Disconnect other VNC sessions when connecting
  -Shared=0

  -MenuKey=Scroll_Lock
  -ViewOnly=0

  -AcceptClipboard=1
  -SendPrimary=1

  # Because we use SSH tunnels, we do not need to use IPv6
  -UseIPv6=0

  # We select quality level ourselves
  -AutoSelect=0

  # Transfer raw
  -PreferredEncoding=Raw
  # Disable custom compression
  -CustomCompressLevel=0
  -CompressLevel=9
  # Disable JPEG compression
  -NoJPEG=1
  -QualityLevel=9
  # If 17 ms is for 60 Hz, then 4 ms is for 240 Hz
  -PointerEventInterval=4
  # 0 meaning 8 colors, 1 meaning 64 colors (the default), 2 meaning 256 colors
  -LowColorLevel=2
  -FullColor

  # Increase clipboard size to 100 Mb
  -MaxCutText="\$((1024 * 1024 * 100))"

  -RemoteResize=1

  -SecurityTypes=VncAuth

  # Do not show some dialogs
  -AlertOnFatalError=0
  -ReconnectOnError=0

  -FullScreen
  -FullScreenMode=All
  -FullscreenSystemKeys
' || true

if [ "${SHELLVNC_IS_DEVELOPMENT}" = "1" ]; then
  vnc_args="\${vnc_args}"'
    # Default is "*:stderr:30"
    -Log="*:stderr:30"
  '
else
  vnc_args="\${vnc_args}"'
    # Disable logging on production (this might change in the future)
    -Log="*:stderr:0"
  '
fi

# Remove comments and empty lines
vnc_args="\$(echo "\${vnc_args}" | sed -En 's/^[[:space:]]*([^#[:space:]].+)\$/\1/p' | tr '\n' ' ')" || true

echo "vncviewer \${vnc_args} \"127.0.0.1:\$(cat "${SHELLVNC_PATH_TO_FILE_WITH_USER_PORT}")\"" || true
eval "vncviewer \${vnc_args} \"127.0.0.1:\$(cat "${SHELLVNC_PATH_TO_FILE_WITH_USER_PORT}")\"" || true

openbox --exit
EOF
    sudo chmod +x /etc/xdg/openbox/autostart || return "$?"

    cat << EOF | sudo tee /usr/share/xsessions/shellvnc.desktop > /dev/null || return "$?"
[Desktop Entry]
Name=ShellVNC
Comment=ShellVNC
Exec=/usr/bin/openbox-session
TryExec=/usr/bin/openbox-session
Icon=openbox
Type=Application
EOF

    shellvnc_print_success_decrease_prefix "Creating desktop entry: success!" || return "$?"

    shellvnc_print_warning "Please, restart your display manager (or just reboot) for new desktop entry to be shown." || return "$?"
    # ========================================

    shellvnc_print_success_decrease_prefix "Installing server: success!" || return "$?"
  fi

  if [ "${type}" = "client" ] || [ "${type}" = "both" ]; then
    shellvnc_print_info_increase_prefix "Installing client..." || return "$?"

    shellvnc_commands "${_SHELLVNC_COMMANDS_ACTION_INSTALL}" vncviewer pactl ssh sshpass usbip || return "$?"

    shellvnc_print_success_decrease_prefix "Installing client: success!" || return "$?"
  fi

  shellvnc_print_success_decrease_prefix "Installation: success!" || return "$?"
}

shellvnc_required_after_function "${BASH_SOURCE[0]}" "$@" || return "$?" 2> /dev/null || exit "$?"
