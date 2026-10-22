# Lampac NextGen runtime image for Pelican / Pterodactyl
# Base: yolks dotnet_10 (user "container", tini + /entrypoint.sh are inherited)
FROM ghcr.io/parkervcp/yolks:dotnet_10

LABEL org.opencontainers.image.description="Yolks dotnet_10 + Chrome, GStreamer, ImageMagick, ICU for Lampac NextGen"

USER root
ARG TARGETARCH
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl unzip xz-utils \
        fontconfig \
        gstreamer1.0-libav gstreamer1.0-plugins-bad gstreamer1.0-plugins-base \
        gstreamer1.0-plugins-base-apps gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly \
        gstreamer1.0-tools libgstreamer-plugins-base1.0-0 libgstreamer1.0-0 \
        imagemagick libjpeg-dev libnspr4 libpng-dev libwebp-dev xvfb \
    # ICU: package name depends on the Debian release (libicu72, libicu76, ...)
    && apt-get install -y --no-install-recommends \
        "$(apt-cache search --names-only '^libicu[0-9]+$' | awk '{print $1}' | sort -V | tail -1)" \
    && mkdir -p /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix \
    && case "$TARGETARCH" in \
         arm64) CHROME_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_arm64.deb" ;; \
         amd64) CHROME_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" ;; \
         *) echo "Unsupported TARGETARCH: $TARGETARCH" && exit 1 ;; \
       esac \
    && curl -fSL -o /tmp/chrome.deb "$CHROME_URL" \
    && apt-get install -y --no-install-recommends /tmp/chrome.deb \
    && rm -f /tmp/chrome.deb \
    && ln -sf /usr/bin/google-chrome-stable /usr/bin/chromium \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Same runtime settings as the official Lampac image (ICU is present now)
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_RUNNING_IN_CONTAINER=true

USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container
