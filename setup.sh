#!/bin/bash
# Local development setup - builds the container image locally.
# For end-user installation, use install.sh which pulls from ghcr.io.
set -euo pipefail

CONTAINER_NAME="dev"
DEV_ROOT="/var/local/${CONTAINER_NAME}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


# Create directories for isolated dev environment
echo "==> Creating persistent directories..."
sudo mkdir -p "${DEV_ROOT}"/{home,projects}
sudo chown "$(id -u):$(id -g)" "${DEV_ROOT}"/{home,projects}

# Set up helix config
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

# Create first-run init script for rustup and oh-my-zsh
cat > "${DEV_ROOT}/home/.devenv-init.sh" << 'INITEOF'
#!/bin/bash
set -euo pipefail

echo "==> First run setup..."

# Install oh-my-zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Install rustup
if ! command -v rustup &> /dev/null; then
    echo "Installing rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path

    # Add to .zshrc if not already there
    if ! grep -q 'cargo/env' "$HOME/.zshrc" 2>/dev/null; then
        echo 'source "$HOME/.cargo/env"' >> "$HOME/.zshrc"
    fi

    # Source for current session
    source "$HOME/.cargo/env"

    # Install common components
    rustup component add rust-src rust-analyzer clippy rustfmt
fi

echo "==> First run setup complete!"
echo ""

# Self-destruct
rm -f "$HOME/.devenv-init.sh"

# Start zsh
exec zsh
INITEOF
chmod +x "${DEV_ROOT}/home/.devenv-init.sh"

# Create .zshrc that triggers init on first run
cat > "${DEV_ROOT}/home/.zshrc" << 'ZSHEOF'
# Run first-time setup if needed
if [[ -f "$HOME/.devenv-init.sh" ]]; then
    source "$HOME/.devenv-init.sh"
fi

# Source cargo env if it exists
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
ZSHEOF

# Build the container image
echo "==> Building container image..."
podman build -t localhost/gamedev:latest "${SCRIPT_DIR}"

# Create the distrobox
echo "==> Creating distrobox container..."
distrobox create \
    --name "${CONTAINER_NAME}" \
    --home "${DEV_ROOT}/home" \
    --volume "${DEV_ROOT}/projects:${DEV_ROOT}/projects:Z" \
    --image localhost/gamedev:latest

echo ""
echo "==> Setup complete!"
echo ""
echo "To enter the container:"
echo "    distrobox enter ${CONTAINER_NAME}"
echo ""
echo "Projects directory: ${DEV_ROOT}/projects"
echo "Container home: ${DEV_ROOT}/home"
echo ""
echo "Clone your project into ${DEV_ROOT}/projects or work directly there."
