#!/bin/bash
# One-shot installer: pull the gamedev image and create the `dev` container.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/cgorto/dev-container/main/install.sh | bash
set -euo pipefail

GITHUB_USER="cgorto"
CONTAINER_NAME="dev"
IMAGE="ghcr.io/${GITHUB_USER}/gamedev:latest"
INI_URL="https://raw.githubusercontent.com/${GITHUB_USER}/dev-container/main/distrobox.ini"

echo "==> Installing ${CONTAINER_NAME} from ${IMAGE}"

# Required tools.
for cmd in distrobox podman curl; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: $cmd is not installed" >&2
        exit 1
    fi
done

# Refuse to clobber an existing container.
if podman container exists "$CONTAINER_NAME"; then
    cat >&2 <<EOF
Error: container '${CONTAINER_NAME}' already exists.
To recreate it:
    distrobox stop ${CONTAINER_NAME}
    distrobox rm ${CONTAINER_NAME}
    bash $0
EOF
    exit 1
fi

echo "==> Pulling image..."
podman pull "$IMAGE"

# Fetch the ini and assemble.
echo "==> Creating container..."
ini=$(mktemp --suffix=.ini)
trap 'rm -f "$ini"' EXIT
curl -fsSL "$INI_URL" -o "$ini"
distrobox assemble create --file "$ini"

cat <<EOF

==> Done.

Enter with: distrobox enter ${CONTAINER_NAME}
EOF
