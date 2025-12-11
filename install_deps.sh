#!/bin/bash
set -exuo pipefail

### 🔧 Base Development Tools
echo "Installing base development tools..."
pacman -S --noconfirm --needed \
    base-devel \
    git \
    cmake \
    ninja \
    ccache \
    gdb \
    lldb

### 🦀 Compilers & LLVM (for daScript clang bindings)
echo "Installing compilers and LLVM..."
pacman -S --noconfirm --needed \
    gcc \
    clang \
    llvm \
    lld

### 🦀 Rust (rustup will be installed per-user on first run)
echo "Installing rustup prerequisites..."
pacman -S --noconfirm --needed \
    curl

### 🎮 Vulkan SDK (for NRI)
echo "Installing Vulkan development packages..."
pacman -S --noconfirm --needed \
    vulkan-devel \
    vulkan-headers \
    vulkan-tools \
    vulkan-validation-layers \
    spirv-tools \
    glslang \
    shaderc

### 🖥️ SDL3 dependencies
echo "Installing SDL3 build dependencies..."
pacman -S --noconfirm --needed \
    libx11 \
    libxext \
    libxrandr \
    libxcursor \
    libxi \
    libxinerama \
    libxkbcommon \
    wayland \
    wayland-protocols \
    libdecor \
    pipewire \
    libpulse \
    alsa-lib \
    mesa

### 🛠️ Additional useful tools
echo "Installing additional tools..."
pacman -S --noconfirm --needed \
    helix \
    zsh \
    ripgrep \
    fd \
    htop \
    renderdoc

### 🧹 Cleanup
echo "Cleaning up..."
pacman -Scc --noconfirm

echo "Done! Development environment ready."
