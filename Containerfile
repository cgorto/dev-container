FROM scratch AS ctx
COPY . /build

FROM docker.io/archlinux/archlinux:latest

# Enable parallel downloads and update system
RUN sed -i 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf && \
    pacman -Syu --noconfirm

# Mount cache for faster rebuilds and install dependencies
RUN --mount=type=cache,dst=/var/cache/pacman/pkg \
    --mount=type=bind,from=ctx,source=/build,target=/build \
    /build/install_deps.sh

# Set zsh as default shell for new users
RUN sed -i 's|SHELL=/bin/bash|SHELL=/usr/bin/zsh|' /etc/default/useradd
