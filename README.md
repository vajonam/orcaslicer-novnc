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
- `VGL_DISPLAY=egl`
- `NOVNC_PORT=8080`
- `VNC_PORT=5900`
- `VNC_RESOLUTION=1280x800`
- `VNC_PASSWORD=`
- `ORCA_GTK_THEME=Adwaita:dark` (default dark theme, override if needed)

## Build Arguments

- `CUDA_IMAGE_TAG=13.0.1-runtime-ubuntu24.04`
- `ORCASLICER_VERSION=latest`
- `VIRTUALGL_VERSION=3.1.1-20240228`
- `TURBOVNC_VERSION=3.1.1-20240127`

## Build/Cache Notes

The Dockerfile is optimized for faster rebuilds:

- Multi-stage build (`runtime-base`, `orca-fetch`, `final`)
- BuildKit apt cache mounts
- Orca download/extract isolated to a version-keyed stage
- `.dockerignore` excludes large local folders (`data`, `prints`, `.git`)

## Single-Window Session Behavior

- Openbox is used only for focus/placement.
- OrcaSlicer runs as the main app process under `supervisord`.
- Openbox app rules disable Openbox decoration for Orca so the app keeps a single titlebar/decorator.

## Links

- [OrcaSlicer](https://github.com/SoftFever/OrcaSlicer)
- [TurboVNC](https://www.turbovnc.org/)
- [VirtualGL](https://virtualgl.org/)
- [Supervisor](http://supervisord.org/)
