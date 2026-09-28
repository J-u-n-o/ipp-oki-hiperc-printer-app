#!/bin/sh
set -e

# Default to UID/GID 1000 if not specified by the user
USER_ID=${PUID:-1000}
GROUP_ID=${PGID:-1000}
USER_NAME="papplrun"
GROUP_NAME="papplrun"

echo "Checking execution permissions... Run As: UID=$USER_ID, GID=$GROUP_ID"

# 1. Create the matching group if it doesn't exist
if ! getent group "$GROUP_ID" >/dev/null 2>&1; then
    groupadd -g "$GROUP_ID" "$GROUP_NAME"
else
    GROUP_NAME=$(getent group "$GROUP_ID" | cut -d: -f1)
fi

# 2. Create the matching user if it doesn't exist
if ! getent passwd "$USER_ID" >/dev/null 2>&1; then
    useradd -u "$USER_ID" -g "$GROUP_ID" -m -s /sbin/nologin "$USER_NAME"
else
    USER_NAME=$(getent passwd "$USER_ID" | cut -d: -f1)
fi

# 3. Ensure the runtime user owns the persistent volume data mapping
mkdir -p /var/spool/pappl
chown -R "$USER_ID:$GROUP_ID" /var/spool/pappl

# 4. If running commands as root, step down to the specified non-root user
if [ "$(id -u)" = '0' ]; then
    # Execute the primary process using gosu to maintain proper signal handling
    exec gosu "$USER_NAME" "$@"
fi

# Fallback if already running as non-root
exec "$@"
