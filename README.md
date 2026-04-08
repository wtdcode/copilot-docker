# copilot-docker

One Docker image based on Ubuntu 24.04 with both [GitHub Copilot CLI](https://www.npmjs.com/package/@github/copilot) and [Claude Code](https://code.claude.com/docs/en/quickstart) pre-installed.

## What's included

- Ubuntu 24.04 (unminimized)
- Node.js LTS + latest npm (via [n](https://github.com/tj/n))
- GitHub Copilot CLI (`@github/copilot`)
- Claude Code installed via the official quickstart installer
- Common tools: git, curl, fish, vim, sudo, tmux, ripgrep
- Locale: `en_US.UTF-8`
- [telegram-send](https://github.com/rahiel/telegram-send) for hook notifications

## Usage

```bash
# Pull from Docker Hub
docker pull lazymio/vibe:latest

# Run with defaults (user: mio, UID/GID: 1000/1000, shell: fish)
docker run --rm -it lazymio/vibe:latest

# Custom user
docker run --rm -it \
  -e USER_NAME=alice \
  -e USER_UID=1001 \
  -e USER_GID=1001 \
  lazymio/vibe:latest

# Match host user
docker run --rm -it \
  -e USER_NAME=$(whoami) \
  -e USER_UID=$(id -u) \
  -e USER_GID=$(id -g) \
  lazymio/vibe:latest
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `USER_NAME` | `mio` | Username to create |
| `USER_UID` | `1000` | User UID |
| `USER_GID` | `1000` | User GID |
| `BOT_TOKEN` | (unset) | Telegram bot token for notifications |
| `ADMIN_ID` | (unset) | Telegram chat ID for notifications |
| `ANTHROPIC_AUTH_TOKEN` | `a` | Used by the generated `claude-bootstrap` fish function for first-time Claude auth setup |
| `ANTHROPIC_BASE_URL` | `b` | Used by the generated `claude-bootstrap` fish function for first-time Claude auth setup |
| `CLAUDE_CODE_OAUTH_TOKEN` | (unset) | Claude Code OAuth token written into fish config on startup |
| `GH_TOKEN` | (unset) | GitHub token written into fish config on startup |
| `GITHUB_TOKEN` | (unset) | GitHub token written into fish config on startup |

The created user has `NOPASSWD:ALL` sudo access and uses `fish` as the default shell.

If `CLAUDE_CODE_OAUTH_TOKEN`, `GH_TOKEN`, or `GITHUB_TOKEN` is set, the shared entrypoint writes them into `~/.config/fish/config.fish` so new fish shells and tmux panes inherit them.

The entrypoint always writes a `claude-bootstrap` fish function into `~/.config/fish/config.fish`. That function runs `claude` as `ANTHROPIC_AUTH_TOKEN=... ANTHROPIC_BASE_URL=... claude`, using the provided `ANTHROPIC_AUTH_TOKEN` and `ANTHROPIC_BASE_URL` values or falling back to placeholder defaults `a` and `b`. This is useful for the first Claude auth bootstrap before switching over to `CLAUDE_CODE_OAUTH_TOKEN`.

## Telegram Notifications

The image includes [telegram-send](https://github.com/rahiel/telegram-send) plus both hook templates:

- [Copilot hooks](https://docs.github.com/en/copilot/customizing-copilot/copilot-hooks) in `~/.copilot/hooks/tg.json`, sending notifications on `agentStop` and `sessionEnd`
- [Claude Code hooks](https://code.claude.com/docs/en/hooks) in `~/.claude/settings.json`, sending notifications on `Stop` and `StopFailure`

To enable, pass `BOT_TOKEN` and `ADMIN_ID`:

```bash
docker run --rm -it \
  -e BOT_TOKEN=123456:ABC-DEF... \
  -e ADMIN_ID=your_chat_id \
  lazymio/vibe:latest
```

Notifications include the event type, hostname, working directory, and the last assistant message (up to 500 chars) when available.

If `BOT_TOKEN` or `ADMIN_ID` is not set, telegram-send will not be configured and hooks will silently skip notifications.

> **Note:** Do not mount a volume directly to `$HOME` (e.g., `-v /host/path:/home/mio`). Instead, mount subdirectories (e.g., `-v ~/.copilot:/home/mio/.copilot`). The entrypoint copies default config files (like `.tmux.conf`) into `$HOME` at startup, which would fail if the entire home directory is an external mount.

## Build locally

```bash
docker build -t lazymio/vibe .

docker run --rm -it lazymio/vibe
```
