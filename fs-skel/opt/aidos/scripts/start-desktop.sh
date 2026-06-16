#!/bin/bash
DISPLAY="${1:-:0}"
export DISPLAY="$DISPLAY"

killall Xorg 2>/dev/null || true
rm -f /tmp/.X${DISPLAY#:}-lock /tmp/.X11-unix/X${DISPLAY#:} 2>/dev/null || true

echo "Starting Xorg on display $DISPLAY..."
Xorg "$DISPLAY" vt1 -auth /home/aidos/.Xauthority &
X_PID=$!

for i in $(seq 1 30); do
    if [ -e "/tmp/.X11-unix/X${DISPLAY#:}" ]; then
        echo "X server ready on $DISPLAY"
        break
    fi
    if ! kill -0 $X_PID 2>/dev/null; then
        echo "ERROR: X server died. Check /var/log/Xorg.0.log"
        exit 1
    fi
    sleep 0.5
done

[ -e "/tmp/.X11-unix/X${DISPLAY#:}" ] || { echo "ERROR: X not ready. Check /var/log/Xorg.0.log"; exit 1; }

echo "Starting x11vnc..."
x11vnc -display "$DISPLAY" -forever -shared -nopw -rfbport 5901 -noxdamage &
x11vnc_PID=$!
sleep 1

echo "Starting XFCE..."
startxfce4 &

echo "DONE: XFCE on :0, x11vnc on :5901"
wait $X_PID