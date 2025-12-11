#!/bin/bash
set -euo pipefail

#############################################
# CONFIGURE THIS
GITHUB_USER="cgorto"
#############################################

CONTAINER_NAME="dev"
DEV_ROOT="/var/local/${CONTAINER_NAME}"
IMAGE="ghcr.io/${GITHUB_USER}/gamedev:latest"

echo "==> Installing gamedev container from ${IMAGE}"

# Check dependencies
if ! command -v distrobox &> /dev/null; then
    echo "Error: distrobox is not installed"
    exit 1
fi

if ! command -v podman &> /dev/null; then
    echo "Error: podman is not installed"
    exit 1
fi

# Check if container already exists
if distrobox list | grep -q "^${CONTAINER_NAME} "; then
    echo "Error: Container '${CONTAINER_NAME}' already exists"
    echo "To reinstall, run:"
    echo "    distrobox stop ${CONTAINER_NAME}"
    echo "    distrobox rm ${CONTAINER_NAME}"
    exit 1
fi

# Create directories for isolated dev environment
echo "==> Creating persistent directories..."
sudo mkdir -p "${DEV_ROOT}"/{home,projects}
sudo chown "$(id -u):$(id -g)" "${DEV_ROOT}"/{home,projects}

# Set up helix config
echo "==> Configuring helix editor..."
mkdir -p "${DEV_ROOT}/home/.config/helix"

cat > "${DEV_ROOT}/home/.config/helix/config.toml" << 'EOF'
theme = "catppuccin_mocha"

[editor]
bufferline = "multiple"
color-modes = true
cursorline = true

[editor.inline-diagnostics]
cursor-line = "info"
other-lines = "error"

EOF

cat > "${DEV_ROOT}/home/.config/helix/languages.toml" << 'EOF'
[[language]]
name = "rust"
auto-format = true

[[language]]
name = "cpp"
auto-format = true
formatter = { command = "clang-format", args = ["-style=file"] }

[[language]]
name = "glsl"
scope = "source.glsl"
file-types = ["vert", "frag", "comp", "geom", "tesc", "tese"]
comment-token = "//"
indent = { tab-width = 4, unit = "    " }
EOF

# Create .distroboxrc to set zsh as the shell (distrobox mirrors host shell by default)
echo "==> Configuring distrobox to use zsh..."
cat > "${DEV_ROOT}/home/.distroboxrc" << 'EOF'
SHELL=/usr/bin/zsh
EOF

# Create first-run init script for rustup and oh-my-zsh
echo "==> Creating first-run init script..."
cat > "${DEV_ROOT}/home/.first-run-setup.sh" << 'INITEOF'
#!/bin/bash
set -euo pipefail

MARKER_FILE="$HOME/.devenv-initialized"

# Skip if already initialized
if [[ -f "$MARKER_FILE" ]]; then
    return 0 2>/dev/null || exit 0
fi

echo "==> First run setup..."

# Install oh-my-zsh (this will create a new .zshrc)
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Append our customizations to the oh-my-zsh .zshrc
echo "Configuring zsh..."
cat >> "$HOME/.zshrc" << 'ZSHCUSTOM'

# === Custom additions ===

# Cargo environment
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Helix alias
alias hx='helix'

# NVIDIA Vulkan ICD for distrobox (host passthrough)
export VK_ICD_FILENAMES=/run/host/usr/share/vulkan/icd.d/nvidia_icd.x86_64.json
ZSHCUSTOM

# Install rustup
if ! command -v rustup &> /dev/null; then
    echo "Installing rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path

    # Source for current session
    source "$HOME/.cargo/env"

    # Install common components
    rustup component add rust-src rust-analyzer clippy rustfmt
fi

# Mark as initialized
touch "$MARKER_FILE"

echo "==> First run setup complete!"
echo ""
INITEOF
chmod +x "${DEV_ROOT}/home/.first-run-setup.sh"

# Create initial .zshrc that triggers first-run setup
# (oh-my-zsh will replace this, but not before our script runs)
cat > "${DEV_ROOT}/home/.zshrc" << 'ZSHEOF'
# First-time setup (runs once, then oh-my-zsh takes over)
if [[ -f "$HOME/.first-run-setup.sh" ]] && [[ ! -f "$HOME/.devenv-initialized" ]]; then
    source "$HOME/.first-run-setup.sh"
fi
ZSHEOF

# Also create .bashrc that can trigger setup if user enters via bash
cat > "${DEV_ROOT}/home/.bashrc" << 'BASHEOF'
# Default Arch bashrc
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# First-time setup (in case user enters via bash first)
if [[ -f "$HOME/.first-run-setup.sh" ]] && [[ ! -f "$HOME/.devenv-initialized" ]]; then
    echo "Running first-time setup..."
    bash "$HOME/.first-run-setup.sh"
    echo "Setup complete. Launching zsh..."
    exec zsh
fi

# Source cargo if available
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
BASHEOF

# Pull the image
echo "==> Pulling container image..."
podman pull "${IMAGE}"

# Create the distrobox
echo "==> Creating distrobox container..."
distrobox create \
    --name "${CONTAINER_NAME}" \
    --home "${DEV_ROOT}/home" \
    --volume "${DEV_ROOT}/projects:${DEV_ROOT}/projects:Z" \
    --init \
    --nvidia \
    --image "${IMAGE}"

echo ""
echo "==> Setup complete!"
echo ""
echo "To enter the container:"
echo "    distrobox enter ${CONTAINER_NAME}"
echo ""
echo "Projects directory: ${DEV_ROOT}/projects"
echo "Container home: ${DEV_ROOT}/home"
echo ""
