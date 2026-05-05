# dev-container

Personal dev container for game and graphics work, run via [distrobox](https://distrobox.it/).

Arch base image with Vulkan SDK, Odin, Slang, OLS, and the usual build tools.
HOME is the host home, so all dotfiles, ssh keys, and editor state are shared.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/cgorto/dev-container/main/install.sh | bash
distrobox enter dev
```

That pulls `ghcr.io/cgorto/gamedev:latest` and creates the `dev` container per
[`distrobox.ini`](./distrobox.ini).

Optionally reinstall any npm CLIs you use (these are intentionally not baked
into the image so they stay fresh):

```sh
sudo npm install -g \
    @gltf-transform/cli \
    @google/gemini-cli \
    @openai/codex \
    pnpm
```

## Build the image locally

```sh
podman build -t localhost/gamedev:latest .

# Point distrobox.ini at the local image for the create step.
sed 's|ghcr.io/cgorto/gamedev:latest|localhost/gamedev:latest|' \
    distrobox.ini > /tmp/dev.ini
distrobox assemble create -f /tmp/dev.ini
```

## Refresh the image (monthly-ish)

Arch is rolling, so to pick up new packages just rebuild:

```sh
podman build --no-cache -t localhost/gamedev:latest .
podman push localhost/gamedev:latest ghcr.io/cgorto/gamedev:latest
```

To bump pinned tools (Odin / OLS / Slang), edit the version constants at the
top of [`install_deps.sh`](./install_deps.sh) before building.

## Recreate the container

```sh
distrobox stop dev
distrobox rm dev
distrobox assemble create -f distrobox.ini
```
