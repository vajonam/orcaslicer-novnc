#!/bin/bash
set -e
rm -f /tmp/.X*-lock
rm -f /tmp/.X11-unix/X*
# TurboVNC/Xvnc expects this socket dir to be root-owned with sticky bit.
mkdir -p /tmp/.X11-unix
chown root:root /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix
export DISPLAY=${DISPLAY:-:0}
DISPLAY_NUMBER=$(echo $DISPLAY | cut -d: -f2)
export NOVNC_PORT=${NOVNC_PORT:-8080}
export VNC_PORT=${VNC_PORT:-5900}
export VNC_RESOLUTION=${VNC_RESOLUTION:-1280x800}
if [ -n "$VNC_PASSWORD" ]; then
  mkdir -p /home/slic3r/.vnc
  echo "$VNC_PASSWORD" | vncpasswd -f > /home/slic3r/.vnc/passwd
  chmod 0600 /home/slic3r/.vnc/passwd
  export VNC_SEC=""
else
  export VNC_SEC="-securitytypes TLSNone,X509None,None"
fi
export LOCALFBPORT=$((${VNC_PORT} + DISPLAY_NUMBER))
if [ -n "$ENABLEHWGPU" ] && [ "$ENABLEHWGPU" = "true" ]; then
  export VGLRUN="/usr/bin/vglrun"
else 
  export VGLRUN=
fi

export SUPD_LOGLEVEL="${SUPD_LOGLEVEL:-TRACE}"
export VGL_DISPLAY="${VGL_DISPLAY:-egl}"
export ORCA_GTK_THEME="${ORCA_GTK_THEME:-Adwaita:dark}"
export ORCA_COMPAT_PROFILE="${ORCA_COMPAT_PROFILE:-x11-hints}"
export ORCA_XDG_SESSION_TYPE="${ORCA_XDG_SESSION_TYPE:-}"
export ORCA_XDG_CURRENT_DESKTOP="${ORCA_XDG_CURRENT_DESKTOP:-}"
export ORCA_XDG_SESSION_DESKTOP="${ORCA_XDG_SESSION_DESKTOP:-}"
export ORCA_GTK_CSD="${ORCA_GTK_CSD:-}"
export ORCA_GDK_DISABLE="${ORCA_GDK_DISABLE:-}"
export ORCA_DBUS_SESSION_BUS_ADDRESS="${ORCA_DBUS_SESSION_BUS_ADDRESS:-}"

apply_orca_compat_profile() {
  case "${ORCA_COMPAT_PROFILE}" in
    ""|none)
      ;;
    x11-hints)
      : "${ORCA_XDG_SESSION_TYPE:=x11}"
      : "${ORCA_XDG_CURRENT_DESKTOP:=Openbox}"
      : "${ORCA_XDG_SESSION_DESKTOP:=Openbox}"
      ;;
    x11-hints-dbus)
      : "${ORCA_XDG_SESSION_TYPE:=x11}"
      : "${ORCA_XDG_CURRENT_DESKTOP:=Openbox}"
      : "${ORCA_XDG_SESSION_DESKTOP:=Openbox}"
      ;;
    *)
      echo "Unsupported ORCA_COMPAT_PROFILE: ${ORCA_COMPAT_PROFILE}" >&2
      echo "Supported values: none, x11-hints, x11-hints-dbus" >&2
      exit 1
      ;;
  esac
}

apply_orca_compat_profile

# Ensure GLVND can discover NVIDIA EGL in containerized runtime environments.
# Some setups inject NVIDIA libs but omit the vendor JSON, which causes Mesa llvmpipe fallback.
mkdir -p /usr/share/glvnd/egl_vendor.d
if [ -e /usr/lib/x86_64-linux-gnu/libEGL_nvidia.so.0 ] && [ ! -f /usr/share/glvnd/egl_vendor.d/10_nvidia.json ]; then
  cat > /usr/share/glvnd/egl_vendor.d/10_nvidia.json <<'EOF'
{
  "file_format_version": "1.0.0",
  "ICD": {
    "library_path": "libEGL_nvidia.so.0"
  }
}
EOF
fi

# Set defaults if environment variables are not set
PUID=${PUID:-1000}
PGID=${PGID:-1000}

echo "Starting container with UID: $PUID and GID: $PGID"
if [ -n "${ORCA_COMPAT_PROFILE}" ] && [ "${ORCA_COMPAT_PROFILE}" != "none" ]; then
  echo "Applying Orca compatibility profile: ${ORCA_COMPAT_PROFILE}"
fi

# Update group ID for slic3r group
if [ "$(id -g slic3r)" != "$PGID" ]; then
  groupmod -g "$PGID" slic3r || { echo "Failed to update group ID"; exit 1; }
fi

# Update user ID for slic3r user
if [ "$(id -u slic3r)" != "$PUID" ]; then
  usermod -u "$PUID" slic3r || { echo "Failed to update user ID"; exit 1; }
fi

target_owner="${PUID}:${PGID}"
recursive_chown="${RECURSIVE_CHOWN:-false}"

fix_ownership() {
  local path="$1"
  local recursive="$2"

  if [ ! -e "${path}" ]; then
    return
  fi

  local current_owner
  current_owner="$(stat -c '%u:%g' "${path}" 2>/dev/null || true)"

  if [ "${recursive}" = "true" ] && [ "${current_owner}" != "${target_owner}" ]; then
    chown -R "${target_owner}" "${path}"
  elif [ "${current_owner}" != "${target_owner}" ]; then
    chown "${target_owner}" "${path}"
  fi
}

# Avoid recursive chown by default for faster startups. Enable it explicitly
# when migrating ownership across existing trees is required.
if [ "${recursive_chown}" = "true" ]; then
  fix_ownership /slic3r true
  fix_ownership /home/slic3r true
  fix_ownership /configs true
  fix_ownership /prints true
else
  fix_ownership /slic3r false
  fix_ownership /home/slic3r false
  fix_ownership /configs false
  fix_ownership /prints false
fi

exec gosu slic3r supervisord -e "$SUPD_LOGLEVEL"
