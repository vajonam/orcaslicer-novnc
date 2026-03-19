#!/bin/bash
set -e

unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

# Keep the VNC X session alive with a tiny WM.
# OrcaSlicer itself is started and supervised separately via supervisord.
exec openbox
