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
| `BOT_TOKEN` | (unset) | Telegram bot token for notifications |
| `ADMIN_ID`  | (unset) | Telegram chat ID for notifications   |

The created user has `NOPASSWD:ALL` sudo access and uses `fish` as the default shell.

## Telegram Notifications

The image includes [telegram-send](https://github.com/rahiel/telegram-send) and pre-configured [Copilot hooks](https://docs.github.com/en/copilot/customizing-copilot/copilot-hooks) that send notifications on `agentStop` and `sessionEnd` events.

To enable, pass `BOT_TOKEN` and `ADMIN_ID`:

```bash
docker run --rm -it \
  -e BOT_TOKEN=123456:ABC-DEF... \
  -e ADMIN_ID=your_chat_id \
  lazymio/copilot:latest
```

Notifications include the event type, hostname, working directory, and the last assistant message (up to 500 chars) from the session transcript.

If `BOT_TOKEN` or `ADMIN_ID` is not set, telegram-send will not be configured and hooks will silently skip notifications.

> **Note:** Do not mount a volume directly to `$HOME` (e.g., `-v /host/path:/home/mio`). Instead, mount subdirectories (e.g., `-v ~/.copilot:/home/mio/.copilot`). The entrypoint copies default config files (like `.tmux.conf`) into `$HOME` at startup, which would fail if the entire home directory is an external mount.

## Build locally

```bash
docker build -t lazymio/copilot .
docker run --rm -it lazymio/copilot
```
