# OrcaSlicer noVNC (NVIDIA + VirtualGL)

## Overview

This image runs OrcaSlicer in a browser via noVNC with TurboVNC + VirtualGL and NVIDIA GPU acceleration.

The container is intentionally minimal:

- Ubuntu 24.04 NVIDIA CUDA runtime base
- TurboVNC + noVNC
- Openbox (tiny WM, no full LXDE desktop)
- OrcaSlicer AppImage extracted at build time

## Quick Start

### Use prebuilt image

```bash
docker compose up -d
```

### Build locally

```bash
docker compose -f docker-compose.build.yml up -d --build
```

To pin a specific OrcaSlicer release while building:

```bash
ORCASLICER_VERSION=v2.3.1 docker compose -f docker-compose.build.yml up -d --build
```

To build with broad codec support and extra debug desktop tools:

```bash
MEDIA_PROFILE=broad DEBUG_TOOLS=true docker compose -f docker-compose.build.yml up -d --build
```

For local-only OrcaSlicer `v2.3.2` compatibility testing under noVNC, keep defaults unchanged and inject env vars only for the run you want to test:

```bash
ORCASLICER_VERSION=v2.3.2 docker compose -f docker-compose.build.yml up -d --build
```

Default run with the recommended X11/Openbox session hints:

```bash
docker compose -f docker-compose.build.yml up -d
```

Explicitly force no compatibility profile:

```bash
ORCA_COMPAT_PROFILE=none docker compose -f docker-compose.build.yml up -d
```

Profile 1: X11/Openbox session hints only:

```bash
ORCA_COMPAT_PROFILE=x11-hints docker compose -f docker-compose.build.yml up -d
```

Profile 2: X11/Openbox hints plus optional local D-Bus passthrough:

```bash
ORCA_COMPAT_PROFILE=x11-hints-dbus ORCA_DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-}" docker compose -f docker-compose.build.yml up -d
```

## GPU Acceleration

Set `ENABLEHWGPU=true` to run OrcaSlicer through `vglrun`.

You can verify GPU usage on the host:

```bash
nvidia-smi -l
```

Expected process (when launched): `/slic3r/squashfs-root/bin/orca-slicer`

## Environment Variables

- `DISPLAY=:0`
- `PUID=1000`
- `PGID=1000`
- `SUPD_LOGLEVEL=INFO`
- `ENABLEHWGPU=false`
- `RECURSIVE_CHOWN=false` (`true` recursively fixes ownership on `/slic3r`, `/home/slic3r`, `/configs`, and `/prints` at startup)
- `VGL_DISPLAY=egl`
- `NOVNC_PORT=8080`
- `VNC_PORT=5900`
- `VNC_RESOLUTION=1280x800`
- `VNC_PASSWORD=`
- `ORCA_GTK_THEME=Adwaita:dark` (default dark theme, override if needed)
- `ORCA_COMPAT_PROFILE=x11-hints` (`none`, `x11-hints`, or `x11-hints-dbus`; defaults to the recommended X11/Openbox hints)
- `ORCA_XDG_SESSION_TYPE=`
- `ORCA_XDG_CURRENT_DESKTOP=`
- `ORCA_XDG_SESSION_DESKTOP=`
- `ORCA_GTK_CSD=`
- `ORCA_GDK_DISABLE=`
- `ORCA_DBUS_SESSION_BUS_ADDRESS=`

## Build Arguments

- `CUDA_IMAGE_TAG=13.0.1-runtime-ubuntu24.04`
- `ORCASLICER_VERSION=latest`
- `VIRTUALGL_VERSION=3.1.1-20240228`
- `TURBOVNC_VERSION=3.1.1-20240127`
- `MEDIA_PROFILE=minimal` (`minimal` or `broad`)
- `DEBUG_TOOLS=false` (`true` adds `dbus-x11`, `xdg-utils`, `xterm`)

## Build/Cache Notes

The Dockerfile is optimized for faster rebuilds:

- Multi-stage build (`runtime-base`, `orca-fetch`, `final`)
- BuildKit apt cache mounts
- Orca download/extract isolated to a version-keyed stage
- `.dockerignore` excludes large local folders (`data`, `prints`, `.git`)

## Single-Window Session Behavior

- Openbox is used only for focus/placement.
- OrcaSlicer runs as the main app process under `supervisord`.
- Openbox uses its default configuration; no custom home-directory `.config` tree is seeded by the image.

## Links

- [OrcaSlicer](https://github.com/SoftFever/OrcaSlicer)
- [TurboVNC](https://www.turbovnc.org/)
- [VirtualGL](https://virtualgl.org/)
- [Supervisor](http://supervisord.org/)
