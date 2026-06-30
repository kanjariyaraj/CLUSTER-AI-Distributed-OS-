#!/bin/bash
set -eu

DISPLAY="${1:-:0}"
export DISPLAY="${DISPLAY}"
DISPLAY_NUM="${DISPLAY#:}"
LOG_DIR="/var/log/aidos"
mkdir -p "$LOG_DIR"
chown aidos:aidos "$LOG_DIR" 2>/dev/null || true

killall Xorg 2>/dev/null || true
rm -f "/tmp/.X${DISPLAY_NUM}-lock" "/tmp/.X11-unix/X${DISPLAY_NUM}" 2>/dev/null || true

echo "Starting X server with startx..."
if [ "$(id -un)" = "aidos" ]; then
    startx /usr/bin/startxfce4 -- "$DISPLAY" vt7 -auth /dev/null > "$LOG_DIR/startx.log" 2>&1 &
else
    su - aidos -c "startx /usr/bin/startxfce4 -- $DISPLAY vt7 -auth /dev/null > $LOG_DIR/startx.log 2>&1" &
fi
X_PID=$!

for _ in $(seq 1 20); do
    [ -S "/tmp/.X11-unix/X${DISPLAY_NUM}" ] && break
    sleep 1
done

echo "Starting x11vnc..."
x11vnc -display "$DISPLAY" -forever -shared -nopw -rfbport 5901 -noxdamage > "$LOG_DIR/x11vnc.log" 2>&1 &
X11VNC_PID=$!
sleep 1

echo "DONE: XFCE and x11vnc running (X pid: $X_PID, VNC pid: $X11VNC_PID)"
wait "$X_PID"
