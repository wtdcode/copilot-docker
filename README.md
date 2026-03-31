# copilot-docker

A Docker image based on Ubuntu 24.04 with [GitHub Copilot CLI](https://www.npmjs.com/package/@github/copilot) pre-installed.

## What's included

- Ubuntu 24.04 (unminimized)
- Node.js LTS + latest npm (via [n](https://github.com/tj/n))
- GitHub Copilot CLI (`@github/copilot`)
- Common tools: git, curl, fish, vim, sudo
- Locale: `en_US.UTF-8`

## Usage

```bash
# Pull from Docker Hub
docker pull lazymio/copilot:latest

# Run with defaults (user: mio, UID/GID: 1000/1000, shell: fish)
docker run --rm -it lazymio/copilot:latest

# Custom user
docker run --rm -it \
  -e USER_NAME=alice \
  -e USER_UID=1001 \
  -e USER_GID=1001 \
  lazymio/copilot:latest

# Match host user
docker run --rm -it \
  -e USER_NAME=$(whoami) \
  -e USER_UID=$(id -u) \
  -e USER_GID=$(id -g) \
  lazymio/copilot:latest
```

## Environment Variables

| Variable    | Default | Description       |
|-------------|---------|-------------------|
| `USER_NAME` | `mio`   | Username to create |
| `USER_UID`  | `1000`  | User UID          |
| `USER_GID`  | `1000`  | User GID          |

The created user has `NOPASSWD:ALL` sudo access and uses `fish` as the default shell.

## Build locally

```bash
docker build -t lazymio/copilot .
docker run --rm -it lazymio/copilot
```
