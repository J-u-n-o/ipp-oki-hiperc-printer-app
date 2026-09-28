#!/bin/sh
set -e

# Default to UID/GID 1000 if not specified by the user
USER_ID=${UID:-1000}
GROUP_ID=${GID:-1000}
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


echo 3. Ensure the runtime user owns the persistent volume data mapping
mkdir -p /var/spool/pappl
chown -R "$USER_ID:$GROUP_ID" /var/spool/pappl
mkdir -p /var/spool/pappl
chown -R "$USER_ID:$GROUP_ID" /var/spool/pappl
mkdir -p /var/lib/legacy-printer-app
chown -R "$USER_ID:$GROUP_ID" /var/lib/legacy-printer-app


rm -rf /run/dbus/pid || true

echo "=============================================="
echo "Starting D-Bus"
echo "=============================================="

mkdir -p /run/dbus
dbus-daemon --system --fork

if [ ! -S /run/dbus/system_bus_socket ]; then
    echo "ERROR: D-Bus system socket was not created"
    exit 1
fi

echo "D-Bus ready:"
ls -l /run/dbus/system_bus_socket


echo "=============================================="
echo "Starting Avahi"
echo "=============================================="

mkdir -p /run/avahi-daemon

avahi-daemon --daemonize --no-chroot

for i in $(seq 1 50); do
    if [ -S /run/avahi-daemon/socket ]; then
        break
    fi
    sleep 0.1
done

if [ ! -S /run/avahi-daemon/socket ]; then
    echo "ERROR: Avahi socket was not created"
    exit 1
fi

echo "Avahi ready:"
ls -l /run/avahi-daemon/socket


echo "=============================================="
echo "Starting application"
echo "=============================================="

echo 4. If running commands as root, step down to the specified non-root user
#if [ "$(id -u)" = '0' ]; then
#    # Execute the primary process using gosu to maintain proper signal handling
#    exec gosu "$USER_NAME" "$@"
#fi

echo Fallback if already running as non-root
exec "$@"
