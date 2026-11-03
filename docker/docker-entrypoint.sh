#!/bin/sh
set -e

# Default to UID/GID 1000 if not specified by the user
USER_ID=${UID:-1000}
GROUP_ID=${GID:-1000}
USER_NAME="papplrun"
GROUP_NAME="papplrun"

FULL_HOSTNAME=$(hostname -f)
HOST_NAME="${FULL_HOSTNAME%%.*}"
DOMAIN_NAME="${FULL_HOSTNAME#*.}"

echo "Checking execution permissions... Run On: $(HOST_NAME) : $(DOMAIN_NAME) As: UID=$USER_ID, GID=$GROUP_ID"

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
chown -R "$USER_ID:$GROUP_ID" /var/spool/pappl || true
mkdir -p /var/spool/pappl
chown -R "$USER_ID:$GROUP_ID" /var/spool/pappl || true
mkdir -p /var/lib/legacy-printer-app
# Not recursive due to non writable .../ssl/...
chown "$USER_ID:$GROUP_ID" /var/lib/legacy-printer-app || true
chown "$USER_ID:$GROUP_ID" /var/lib/legacy-printer-app/legacy-printer-app.* || true
chown -R "$USER_ID:$GROUP_ID" /var/lib/legacy-printer-app || true


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

# 1. Add or replace the configurations under the [server] section
sed -i "/^\[server\]/,/^\[/ {
    # If host-name matches, replace it. If we reach the next section and haven't seen it, we'll append it.
    s/^[# ]*host-name=.*/host-name=$HOST_NAME/
    s/^[# ]*domain-name=.*/domain-name=$DOMAIN_NAME/
}" /etc/avahi/avahi-daemon.conf

# 2. Handle cases where the keys didn't exist at all in the [server] section
grep -q "^host-name=" /etc/avahi/avahi-daemon.conf || sed -i "/^\[server\]/a host-name=$HOST_NAME" /etc/avahi/avahi-daemon.conf
grep -q "^domain-name=" /etc/avahi/avahi-daemon.conf || sed -i "/^\[server\]/a domain-name=$DOMAIN_NAME" /etc/avahi/avahi-daemon.conf

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

if [ "$(id -u)" = '0' ]; then
    echo 4. If running commands as root, step down to the specified non-root user "$USER_NAME"
    # Execute the primary process using gosu to maintain proper signal handling
    echo "$@"
    exec gosu "$USER_NAME" "$@"
else
    echo Fallback if already running as non-root
    echo "$@"
    exec "$@"
fi
