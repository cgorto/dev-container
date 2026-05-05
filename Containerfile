# Personal gamedev image. Arch base + Vulkan SDK + Odin + Slang + OLS.
#
# Build:   podman build -t localhost/gamedev:latest .
# Publish: podman push localhost/gamedev:latest ghcr.io/cgorto/gamedev:latest

FROM scratch AS ctx
COPY . /build

FROM docker.io/archlinux/archlinux:latest

# Parallel pacman + system update.
RUN sed -i 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf && \
    pacman -Syu --noconfirm

# All packages and pinned-version tools.
RUN --mount=type=cache,target=/var/cache/pacman/pkg \
    --mount=type=bind,from=ctx,source=/build,target=/build \
    bash /build/install_deps.sh
