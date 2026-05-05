#!/bin/bash
# Installs every tool the gamedev container needs.
# Runs inside the Containerfile build, as root, with /var/cache/pacman/pkg
# as a cache mount and /build as a bind mount.
set -euxo pipefail

# Suppress -debug subpackages from AUR builds so we don't double image size.
sed -i 's/^OPTIONS=(\(.*\)\bdebug\b\(.*\))$/OPTIONS=(\1!debug\2)/' /etc/makepkg.conf

# --- Pacman: official repo packages ------------------------------------------

# Build toolchain.
pacman -S --noconfirm --needed \
    base-devel \
    git \
    unzip \
    zip \
    cmake \
    ninja \
    ccache \
    premake \
    gcc \
    clang \
    llvm \
    lld \
    libc++ \
    gdb \
    lldb \
    riscv64-linux-gnu-gcc \
    binaryen

# Language runtimes / package managers.
pacman -S --noconfirm --needed \
    bun \
    npm \
    luajit \
    love \
    uv

# Media + image tooling.
pacman -S --noconfirm --needed \
    ffmpeg \
    imagemagick \
    openexr \
    poppler

# Editors / language servers.
pacman -S --noconfirm --needed \
    helix \
    lua-language-server

# Vulkan SDK + shader tooling.
pacman -S --noconfirm --needed \
    vulkan-headers \
    vulkan-icd-loader \
    vulkan-tools \
    vulkan-validation-layers \
    vulkan-utility-libraries \
    vulkan-extra-layers \
    vulkan-extra-tools \
    vulkan-html-docs \
    vulkan-intel \
    vulkan-radeon \
    spirv-tools \
    spirv-headers \
    glslang \
    shaderc \
    sdl3 \
    volk \
    nvtop

# Display server, audio, desktop integration.
pacman -S --noconfirm --needed \
    libx11 libxext libxrandr libxcursor libxi libxinerama libxkbcommon \
    libxss libxtst xorg-xauth \
    wayland wayland-protocols libdecor \
    pipewire libpulse alsa-lib jack2 sndio openal mesa \
    wl-clipboard grim zenity

# CLI niceties.
pacman -S --noconfirm --needed \
    bash-completion \
    bc \
    less \
    lsof \
    man-db \
    man-pages \
    htop \
    ripgrep \
    fd \
    tree \
    screen \
    openssh \
    wget \
    rsync \
    curl \
    inetutils \
    mtr \
    traceroute \
    tcpdump \
    socat \
    nss-mdns \
    pigz \
    time \
    words \
    github-cli \
    fzf \
    bat \
    eza \
    zoxide \
    starship \
    git-delta

# --- AUR: bootstrap yay, then install AUR packages ---------------------------

# makepkg refuses to run as root, so create a temporary build user with
# passwordless sudo; remove it after the AUR step.
useradd -m -G wheel builduser
echo 'builduser ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/builduser

# Build & install yay from source.
sudo -u builduser bash -c '
    set -e
    cd /tmp
    git clone --depth=1 https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
'

# AUR packages.
sudo -u builduser yay -S --noconfirm \
    --answerdiff=None \
    --answerclean=None \
    --mflags="--noconfirm" \
    odin-git \
    shader-slang \
    ktx-software-bin \
    glsl_analyzer-bin \
    vscodium-bin

# Tear down the build user.
userdel -r builduser
rm /etc/sudoers.d/builduser
rm -rf /tmp/yay

echo "Done. Image ready."
