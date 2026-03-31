#!/bin/bash
set -e

USER_NAME="${USER_NAME:-mio}"
USER_UID="${USER_UID:-1000}"
USER_GID="${USER_GID:-1000}"

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
    useradd -m -u "$USER_UID" -g "$USER_GID" -s /usr/bin/fish "$USER_NAME"
fi

# Ensure sudoers entry
echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$USER_NAME"
chmod 0440 "/etc/sudoers.d/$USER_NAME"

# Switch to the user and run the command
exec gosu "$USER_NAME" "$@"
