#!/bin/bash
set -e

USER_NAME="${USER_NAME:-mio}"
USER_UID="${USER_UID:-1000}"
USER_GID="${USER_GID:-1000}"

fish_escape() {
    local value="$1"
    value=${value//\\/\\\\}
    value=${value//\"/\\\"}
    value=${value//\$/\\$}
    value=${value//\`/\\\`}
    printf '%s' "$value"
}

write_fish_env_config() {
    local home_dir="$1"
    local fish_dir="$home_dir/.config/fish"
    local fish_config="$fish_dir/config.fish"
    local start_marker="# >>> copilot-docker managed env >>>"
    local end_marker="# <<< copilot-docker managed env <<<"
    local anthropic_auth_token="${ANTHROPIC_AUTH_TOKEN:-a}"
    local anthropic_base_url="${ANTHROPIC_BASE_URL:-b}"
    local temp_file
    local wrote=0

    mkdir -p "$fish_dir"
    touch "$fish_config"

    temp_file=$(mktemp)
    awk -v start="$start_marker" -v end="$end_marker" '
        $0 == start { skip = 1; next }
        $0 == end { skip = 0; next }
        !skip { print }
    ' "$fish_config" > "$temp_file"
    mv "$temp_file" "$fish_config"

    {
        echo "$start_marker"

        if [ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
            printf 'set -gx CLAUDE_CODE_OAUTH_TOKEN "%s"\n' "$(fish_escape "$CLAUDE_CODE_OAUTH_TOKEN")"
            wrote=1
        fi

        if [ -n "$GH_TOKEN" ]; then
            printf 'set -gx GH_TOKEN "%s"\n' "$(fish_escape "$GH_TOKEN")"
            wrote=1
        fi

        if [ -n "$GITHUB_TOKEN" ]; then
            printf 'set -gx GITHUB_TOKEN "%s"\n' "$(fish_escape "$GITHUB_TOKEN")"
            wrote=1
        fi

        if [ -z "$GH_TOKEN" ] && [ -n "$GITHUB_TOKEN" ]; then
            printf 'set -gx GH_TOKEN "%s"\n' "$(fish_escape "$GITHUB_TOKEN")"
            wrote=1
        fi

        if [ -z "$GITHUB_TOKEN" ] && [ -n "$GH_TOKEN" ]; then
            printf 'set -gx GITHUB_TOKEN "%s"\n' "$(fish_escape "$GH_TOKEN")"
            wrote=1
        fi

        printf '\n'
        printf '# Run Claude once with bootstrap auth before relying on CLAUDE_CODE_OAUTH_TOKEN\n'
        printf 'function claude-bootstrap --description "Run Claude Code with bootstrap Anthropic auth"\n'
        printf '    env ANTHROPIC_AUTH_TOKEN="%s" ANTHROPIC_BASE_URL="%s" command claude $argv\n' \
            "$(fish_escape "$anthropic_auth_token")" \
            "$(fish_escape "$anthropic_base_url")"
        printf 'end\n'
        wrote=1

        echo "$end_marker"
    } >> "$fish_config"

    if [ "$wrote" -eq 0 ]; then
        temp_file=$(mktemp)
        awk -v start="$start_marker" -v end="$end_marker" '
            $0 == start { skip = 1; next }
            $0 == end { skip = 0; next }
            !skip { print }
        ' "$fish_config" > "$temp_file"
        mv "$temp_file" "$fish_config"
    fi
}

# Remove existing user/group that occupy the target UID/GID (if different name)
EXISTING_USER=$(getent passwd "$USER_UID" 2>/dev/null | cut -d: -f1 || true)
if [ -n "$EXISTING_USER" ] && [ "$EXISTING_USER" != "$USER_NAME" ]; then
    userdel "$EXISTING_USER" 2>/dev/null || true
fi
EXISTING_GROUP=$(getent group "$USER_GID" 2>/dev/null | cut -d: -f1 || true)
if [ -n "$EXISTING_GROUP" ] && [ "$EXISTING_GROUP" != "$USER_NAME" ]; then
    groupdel "$EXISTING_GROUP" 2>/dev/null || true
fi

# Create group if it doesn't exist
if ! getent group "$USER_GID" > /dev/null 2>&1; then
    groupadd -g "$USER_GID" "$USER_NAME"
fi

# Create user if it doesn't exist
if ! id "$USER_NAME" > /dev/null 2>&1; then
    if [ -d "/home/$USER_NAME" ]; then
        useradd -u "$USER_UID" -g "$USER_GID" -d "/home/$USER_NAME" -s /usr/bin/fish "$USER_NAME"
    else
        useradd -m -u "$USER_UID" -g "$USER_GID" -s /usr/bin/fish "$USER_NAME"
    fi
fi

# Ensure home directory ownership (may be a mount point)
chown "$USER_UID:$USER_GID" "/home/$USER_NAME"

# Copy default config files from /etc/skel if missing
cp -r --update=none /etc/skel/. "/home/$USER_NAME/"

# Configure telegram-send if BOT_TOKEN and ADMIN_ID are set
if [ -n "$BOT_TOKEN" ] && [ -n "$ADMIN_ID" ]; then
    mkdir -p "/home/$USER_NAME/.config"
    cat > "/home/$USER_NAME/.config/telegram-send.conf" <<EOF
[telegram]
token = $BOT_TOKEN
chat_id = $ADMIN_ID
EOF
fi

write_fish_env_config "/home/$USER_NAME"

chown -R "$USER_UID:$USER_GID" "/home/$USER_NAME"

# Ensure sudoers entry
echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$USER_NAME"
chmod 0440 "/etc/sudoers.d/$USER_NAME"

# Switch to the user and run the command
exec gosu "$USER_NAME" "$@"
