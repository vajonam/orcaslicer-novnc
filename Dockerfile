# syntax=docker/dockerfile:1.7

ARG CUDA_IMAGE_TAG=13.0.1-runtime-ubuntu24.04
ARG VIRTUALGL_VERSION=3.1.1-20240228
ARG TURBOVNC_VERSION=3.1.1-20240127
ARG ORCASLICER_VERSION=latest

FROM nvidia/cuda:${CUDA_IMAGE_TAG} AS runtime-base
LABEL authors="vajonam"

ARG VIRTUALGL_VERSION
ARG TURBOVNC_VERSION
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    adwaita-icon-theme \
    bzip2 \
    ca-certificates \
    curl \
    dbus-x11 \
    file \
    gosu \
    gstreamer1.0-gl \
    gstreamer1.0-libav \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-tools \
    gstreamer1.0-x \
    jq \
    libcanberra-gtk3-module \
    libegl1 \
    libfuse2t64 \
    libgl1 \
    libgl1-mesa-dri \
    libglut3.12 \
    libgtk-3-0 \
    libgtk2.0-0 \
    libnvidia-egl-gbm1 \
    libopengl0 \
    libpam0g \
    libwebkit2gtk-4.1-0 \
    libwxbase3.2-1t64 \
    libwxgtk-gl3.2-1t64 \
    libwxgtk-media3.2-1t64 \
    libwxgtk3.2-1t64 \
    libxext6 \
    libxmu6 \
    libxt6 \
    locales \
    locales-all \
    novnc \
    openbox \
    openssl \
    python3 \
    supervisor \
    wget \
    x11-xkb-utils \
    x11-xserver-utils \
    xauth \
    xdg-utils \
    xkb-data \
    xorg \
    xterm \
    && rm -rf /var/lib/apt/lists/*

RUN wget -qO /tmp/virtualgl.deb "https://packagecloud.io/dcommander/virtualgl/packages/any/any/virtualgl_${VIRTUALGL_VERSION}_amd64.deb/download.deb?distro_version_id=35" \
    && wget -qO /tmp/turbovnc.deb "https://packagecloud.io/dcommander/turbovnc/packages/any/any/turbovnc_${TURBOVNC_VERSION}_amd64.deb/download.deb?distro_version_id=35" \
    && dpkg -i /tmp/virtualgl.deb /tmp/turbovnc.deb \
    && rm -f /tmp/virtualgl.deb /tmp/turbovnc.deb

RUN if ! getent group slic3r >/dev/null; then groupadd --system slic3r; fi \
    && if ! id -u slic3r >/dev/null 2>&1; then useradd --system -g slic3r --create-home --home-dir /home/slic3r slic3r; fi \
    && mkdir -p /slic3r /configs/.config/openbox /configs/.local /prints \
    && ln -sfn /configs/.config /home/slic3r/.config \
    && echo 'XDG_DOWNLOAD_DIR="/prints/"' >> /configs/.config/user-dirs.dirs \
    && echo "file:///prints prints" >> /home/slic3r/.gtk-bookmarks \
    && locale-gen en_US \
    && chown -R slic3r:slic3r /slic3r /home/slic3r /configs /prints

ENV PATH="${PATH}:/opt/VirtualGL/bin:/opt/TurboVNC/bin"

FROM runtime-base AS orca-fetch

ARG ORCASLICER_VERSION
WORKDIR /slic3r
COPY get_latest_orcalslicer_release.sh /slic3r/get_latest_orcalslicer_release.sh
COPY validate_orcaslicer_runtime.sh /slic3r/validate_orcaslicer_runtime.sh
RUN chmod +x /slic3r/get_latest_orcalslicer_release.sh /slic3r/validate_orcaslicer_runtime.sh \
    && latest_slic3r="$("/slic3r/get_latest_orcalslicer_release.sh" url "${ORCASLICER_VERSION}")" \
    && slic3r_release_name="$("/slic3r/get_latest_orcalslicer_release.sh" name "${ORCASLICER_VERSION}")" \
    && curl -fsSL "${latest_slic3r}" -o "/slic3r/${slic3r_release_name}" \
    && chmod +x "/slic3r/${slic3r_release_name}" \
    && "/slic3r/${slic3r_release_name}" --appimage-extract \
    && /slic3r/validate_orcaslicer_runtime.sh /slic3r/squashfs-root \
    && rm -f "/slic3r/${slic3r_release_name}"

FROM runtime-base AS final

WORKDIR /slic3r
COPY --from=orca-fetch /slic3r/squashfs-root /slic3r/squashfs-root

COPY entrypoint.sh /entrypoint.sh
COPY supervisord.conf /etc/supervisord.conf
COPY xstartup.sh /etc/turbovnc-xstartup.sh
COPY openbox-rc.xml /home/slic3r/.config/openbox/rc.xml
COPY vncresize.html /usr/share/novnc/index.html
COPY icons/prusaslicer-16x16.png /usr/share/novnc/app/images/icons/novnc-16x16.png
COPY icons/prusaslicer-24x24.png /usr/share/novnc/app/images/icons/novnc-24x24.png
COPY icons/prusaslicer-32x32.png /usr/share/novnc/app/images/icons/novnc-32x32.png
COPY icons/prusaslicer-48x48.png /usr/share/novnc/app/images/icons/novnc-48x48.png
COPY icons/prusaslicer-60x60.png /usr/share/novnc/app/images/icons/novnc-60x60.png
COPY icons/prusaslicer-64x64.png /usr/share/novnc/app/images/icons/novnc-64x64.png
COPY icons/prusaslicer-72x72.png /usr/share/novnc/app/images/icons/novnc-72x72.png
COPY icons/prusaslicer-76x76.png /usr/share/novnc/app/images/icons/novnc-76x76.png
COPY icons/prusaslicer-96x96.png /usr/share/novnc/app/images/icons/novnc-96x96.png
COPY icons/prusaslicer-120x120.png /usr/share/novnc/app/images/icons/novnc-120x120.png
COPY icons/prusaslicer-144x144.png /usr/share/novnc/app/images/icons/novnc-144x144.png
COPY icons/prusaslicer-152x152.png /usr/share/novnc/app/images/icons/novnc-152x152.png
COPY icons/prusaslicer-192x192.png /usr/share/novnc/app/images/icons/novnc-192x192.png

RUN chmod +x /entrypoint.sh /etc/turbovnc-xstartup.sh \
    && chown -R slic3r:slic3r /home/slic3r/.config/openbox \
    && openssl req -x509 -nodes -newkey rsa:2048 \
      -keyout /etc/novnc.pem \
      -out /etc/novnc.pem \
      -days 365 \
      -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=localhost"

VOLUME /configs/
VOLUME /prints/

ENTRYPOINT ["/entrypoint.sh"]
