# syntax=docker/dockerfile:1.7

ARG CUDA_IMAGE_TAG=13.0.1-runtime-ubuntu24.04
ARG VIRTUALGL_VERSION=3.1.1-20240228
ARG TURBOVNC_VERSION=3.1.1-20240127
ARG ORCASLICER_VERSION=latest
ARG MEDIA_PROFILE=minimal
ARG DEBUG_TOOLS=false

FROM nvidia/cuda:${CUDA_IMAGE_TAG} AS base
LABEL authors="vajonam"

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

FROM base AS vnc-fetch
ARG VIRTUALGL_VERSION
ARG TURBOVNC_VERSION
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && curl -fsSL "https://packagecloud.io/dcommander/virtualgl/packages/any/any/virtualgl_${VIRTUALGL_VERSION}_amd64.deb/download.deb?distro_version_id=35" -o /tmp/virtualgl.deb \
    && curl -fsSL "https://packagecloud.io/dcommander/turbovnc/packages/any/any/turbovnc_${TURBOVNC_VERSION}_amd64.deb/download.deb?distro_version_id=35" -o /tmp/turbovnc.deb \
    && rm -rf /var/lib/apt/lists/*

FROM base AS orca-fetch
ARG ORCASLICER_VERSION
WORKDIR /slic3r
COPY get_latest_orcalslicer_release.sh /slic3r/get_latest_orcalslicer_release.sh
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      file \
      jq \
    && chmod +x /slic3r/get_latest_orcalslicer_release.sh \
    && latest_slic3r="$('/slic3r/get_latest_orcalslicer_release.sh' url "${ORCASLICER_VERSION}")" \
    && slic3r_release_name="$('/slic3r/get_latest_orcalslicer_release.sh' name "${ORCASLICER_VERSION}")" \
    && curl -fsSL "${latest_slic3r}" -o "/slic3r/${slic3r_release_name}" \
    && chmod +x "/slic3r/${slic3r_release_name}" \
    && "/slic3r/${slic3r_release_name}" --appimage-extract \
    && rm -f "/slic3r/${slic3r_release_name}" \
    && rm -rf /var/lib/apt/lists/*

FROM base AS final
ARG MEDIA_PROFILE
ARG DEBUG_TOOLS

WORKDIR /slic3r
COPY --from=vnc-fetch /tmp/virtualgl.deb /tmp/virtualgl.deb
COPY --from=vnc-fetch /tmp/turbovnc.deb /tmp/turbovnc.deb
COPY --from=orca-fetch /slic3r/squashfs-root /slic3r/squashfs-root
COPY validate_orcaslicer_runtime.sh /slic3r/validate_orcaslicer_runtime.sh

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

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update \
    && packages=( \
      adwaita-icon-theme \
      bzip2 \
      ca-certificates \
      gosu \
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
      novnc \
      openbox \
      openssl \
      python3 \
      supervisor \
      x11-xkb-utils \
      x11-xserver-utils \
      xauth \
      xkb-data \
    ) \
    && case "${MEDIA_PROFILE}" in \
      minimal) \
        packages+=( \
          gstreamer1.0-gl \
          gstreamer1.0-plugins-base \
          gstreamer1.0-plugins-good \
          gstreamer1.0-x \
        ) \
        ;; \
      broad) \
        packages+=( \
          gstreamer1.0-gl \
          gstreamer1.0-libav \
          gstreamer1.0-plugins-bad \
          gstreamer1.0-plugins-base \
          gstreamer1.0-plugins-good \
          gstreamer1.0-plugins-ugly \
          gstreamer1.0-tools \
          gstreamer1.0-x \
        ) \
        ;; \
      *) \
        echo "Unsupported MEDIA_PROFILE: ${MEDIA_PROFILE}. Use 'minimal' or 'broad'." >&2 \
        && exit 1 \
        ;; \
    esac \
    && if [ "${DEBUG_TOOLS}" = "true" ]; then \
      packages+=(dbus-x11 xdg-utils xterm); \
    fi \
    && apt-get install -y --no-install-recommends \
      "${packages[@]}" \
      /tmp/virtualgl.deb \
      /tmp/turbovnc.deb \
    && rm -f /tmp/virtualgl.deb /tmp/turbovnc.deb \
    && echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && if ! getent group slic3r >/dev/null; then groupadd --system slic3r; fi \
    && if ! id -u slic3r >/dev/null 2>&1; then useradd --system -g slic3r --create-home --home-dir /home/slic3r slic3r; fi \
    && mkdir -p /slic3r /configs/.config/openbox /configs/.local /prints \
    && ln -sfn /configs/.config /home/slic3r/.config \
    && echo 'XDG_DOWNLOAD_DIR="/prints/"' >> /configs/.config/user-dirs.dirs \
    && echo "file:///prints prints" >> /home/slic3r/.gtk-bookmarks \
    && chmod +x /slic3r/validate_orcaslicer_runtime.sh \
    && chmod +x /entrypoint.sh /etc/turbovnc-xstartup.sh \
    && chown -R slic3r:slic3r /slic3r /home/slic3r /configs /prints \
    && /slic3r/validate_orcaslicer_runtime.sh /slic3r/squashfs-root \
    && openssl req -x509 -nodes -newkey rsa:2048 \
      -keyout /etc/novnc.pem \
      -out /etc/novnc.pem \
      -days 365 \
      -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=localhost" \
    && rm -rf /var/lib/apt/lists/*

ENV PATH="${PATH}:/opt/VirtualGL/bin:/opt/TurboVNC/bin"

VOLUME /configs/
VOLUME /prints/

ENTRYPOINT ["/entrypoint.sh"]
