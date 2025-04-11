# Orcaslicer NVIDIA HW accelerated noVNC - Docker Image

## Overview

This container is targetted toward NVIDIA hardware (tested with NVIDIA) to run OrcaSlicer in a web browser with GPU-accelerated OpenGL. It is a fork of the prusaslicer-novnc project (https://github.com/helfrichmichael/prusaslicer-novnc), modified to replace PrusaSlicer with OrcaSlicer.

#### NVIDIA GPU specifc use case

There is already a [linuxserver.io](https://github.com/linuxserver/docker-orcaslicer) repo, but I couldn't get hardware-accelerated GPU rendering working. I had already invested the time into this, and didn't feel like doing it again. It seems pretty niche at the moment. So I will maintain this as long as I use Orcaslicer and they maintain their AppImage distribution. I may end up discontinuing mainttaing this repo. 

## How to use

### Docker
To run this image, you can run the following command: 
```
docker run --detach \
--volume=orcaslicer-novnc-data:/configs/ \
--volume=orcaslicer-novnc-prints:/prints/ \
-p 8080:8080 \
-e SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt" \
--name=orcaslicer-novnc \
ghcr.io/vajonam/orcaslicer-novnc:latest
```

This will bind `/configs/` in the container to a local volume on my machine named `orcaslicer-novnc-data`. Additionally it will bind `/prints/` in the container to `orcaslicer-novnc-prints` locally on your machine, it will bind port `8080` to `8080`, and finally, it will provide an environment variable to keep orcaslicer happy by providing an `SSL_CERT_FILE`.

### Docker Compose
To use the pre-built image, simply clone this repository or copy `docker-compose.yml` and run `docker compose up -d`.

To build a new image, clone this repository and run `docker compose up -f docker-compose.build.yml --build -d`

## Using a VNC Viewer

To use a VNC viewer with the container, the default port for TurobVNC is 5900. You can add this port by adding `-p 5900:5900` to your command to start the container to open this port for access. See note below about ports related to `VNC_PORT` environment variable. 


## GPU Acceleration/Passthrough

Like other Docker containers, you can pass your Nvidia GPU into the container using the `NVIDIA_VISIBLE_DEVICES` and `NVIDIA_DRIVER_CAPABILITIES` envs. You can define these using the value of `all` or by providing more narrow and specific values. This has only been tested on Nvidia GPUs.

In unraid you can set these values during set up, **additionally, please add the "Extra Parameters" with `--runtime=nvidia` to ensure the GPU passes through**. For containers outside of unraid, you can set this by adding the following params or similar  `-e NVIDIA_DRIVER_CAPABILITIES="all" NVIDIA_VISIBLE_DEVICES="all"`. If using Docker Compose, uncomment the enviroment variables in the relevant docker-compose.yaml file.

In addition to the information above, to enable **Hardware 3D acceleration** (which helps with visualizing complex models and  sliced layers), you must set an environment variable. You can do this by either adding `-e ENABLEHWGPU=true` to the `docker run` command or including `- ENABLEHWGPU=true` in your Docker Compose configuration.

Once enabled and started you can verify the GPU is being used by running `nvidia-smi -l` on the HOST machine and you should see `/slic3r/squashfs-root/bin/orca-slicer` as process using the GPU. 

```
+---------------------------------------------------------------------------------------+
| NVIDIA-SMI 535.161.07             Driver Version: 535.161.07   CUDA Version: 12.2     |
|-----------------------------------------+----------------------+----------------------+

.. removed for brevity .. 

+---------------------------------------------------------------------------------------+
| Processes:                                                                            |
|  GPU   GI   CI        PID   Type   Process name                            GPU Memory |
|        ID   ID                                                             Usage      |
|=======================================================================================|
|    0   N/A  N/A   4129827      G   /slic3r/squashfs-root/bin/orca-slicer       262MiB |
+---------------------------------------------------------------------------------------+

*some information above was edited for privacy
```

The `GL Version` on the System Information screen inside the slicer should also show, the GPU model and driver version

<img src="https://github.com/vajonam/orcaslicer-novnc/blob/orcaslicer/images/orcaslicer_screenshot.png" width="300" />


### Other Environment Variables

Below are the default values for various environment variables:

- `DISPLAY=:0`: Sets the DISPLAY variable (usually left as 0).
- `PUID=1000` : default UID, allows the Process UID to be set.
- `PGID=1000` : default GID, allows the Process GID to be set.
- `SUPD_LOGLEVEL=INFO`: Specifies the log level for supervisord. Set to `TRACE` to see output for various commands helps if you are debugging something. See superviosrd manual for possible levels.
- `ENABLEHWGPU=`: Enables HW 3D acceleration. Default is `false` to maintain backward compatability.
- `VGL_DISPLAY=egl`: Advanced setting to target specific cards if you have multiple GPUs. 
- `NOVNC_PORT=8080`: Sets the port for the noVNC HTML5/web interface.
- `VNC_RESOLUTION=1280x800`: Defines the resolution of the VNC server.
- `VNC_PASSWORD=`: Defaults to no VNC password, but you can add one here.
- `VNC_PORT=5900`: Defines the port for the VNC server, allowing direct connections using a VNC client. Note that the `DISPLAY` number is added to the port number (e.g., if your display is :1, the VNC port accepting connections will be `5901`).

## Links

[OrcaSlicer](https://github.com/SoftFever/OrcaSlicer)

[TruboVNC](https://www.turbovnc.org/)

[VirtualGL](https://virtualgl.org/)

[Supervisor](http://supervisord.org/)

[Original PrusaSlicer-novnc](https://github.com/helfrichmichael/prusaslicer-novnc)

