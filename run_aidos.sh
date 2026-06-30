#!/bin/bash
# Run AIDOS ISO in QEMU
# Usage: ./run_aidos.sh [display|vnc|spice] [iso-path] [ram-mb] [cpus]

MODE="${1:-vnc}"
ISO="${2:-out/aidos.iso}"
MEM="${3:-4096}"
SMP="${4:-4}"

SERIAL_LOG="/tmp/aidos-serial-$$.log"

if [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
  QEMU_ACCEL=(-enable-kvm -machine q35 -cpu host)
else
  QEMU_ACCEL=(-machine q35,accel=tcg -cpu max)
  echo "WARNING: /dev/kvm is unavailable; using slower QEMU TCG emulation"
fi

# Kill leftover serial listeners (tail -f / socat processes, NOT QEMU)
pkill -f "^tail -f.*aidos-serial" 2>/dev/null || true
pkill -f "^socat.*aidos-serial" 2>/dev/null || true

port_in_use() {
  ss -H -tln "sport = :$1" 2>/dev/null | grep -q .
}

PORTS=""
add_forward() {
  host_port="$1"
  guest_port="$2"
  label="$3"
  if port_in_use "$host_port"; then
    echo "WARNING: Port $host_port already in use; skipping $label forward"
    return
  fi
  if [ -n "$PORTS" ]; then
    PORTS="${PORTS},"
  fi
  PORTS="${PORTS}hostfwd=tcp:127.0.0.1:${host_port}-:${guest_port}"
}

if [ "${AIDOS_FORWARD_SERVICES:-0}" = "1" ]; then
  add_forward 18080 8080 "API"
  add_forward 18081 8081 "Node"
  add_forward 18082 8082 "Controller"
  add_forward 18083 8083 "Market"
fi
if [ "${AIDOS_FORWARD_RPC:-0}" = "1" ]; then
  add_forward 50052 50052 "RPC"
fi

NETDEV="user,id=net0"
[ -n "$PORTS" ] && NETDEV="${NETDEV},${PORTS}"

if port_in_use 5900; then
  echo "WARNING: Port 5900 already in use; QEMU VNC may fail"
fi

echo "Launching AIDOS ISO: $ISO"
echo " RAM: ${MEM}MB | CPUs: $SMP | Mode: $MODE"
echo " Serial log: $SERIAL_LOG"
if [ "${AIDOS_FORWARD_SERVICES:-0}" = "1" ]; then
  echo " Ports: 18080->8080(API) 18081->8081(Node) 18082->8082(Ctrl) 18083->8083(Market)"
else
  echo " Service port forwarding disabled by default; set AIDOS_FORWARD_SERVICES=1 to enable"
fi
if [ "${AIDOS_FORWARD_RPC:-0}" = "1" ]; then
  echo " RPC port forwarding requested: 50052"
fi
echo ""

case "$MODE" in
  display|gtk)
    qemu-system-x86_64 \
      "${QEMU_ACCEL[@]}" \
      -smp "$SMP" -m "$MEM" \
      -vga virtio -display gtk \
      -device virtio-keyboard-pci -device virtio-tablet-pci \
      -serial "file:$SERIAL_LOG" \
      -cdrom "$ISO" -boot d \
      -netdev "$NETDEV" -device virtio-net-pci,netdev=net0
    ;;
  vnc|vnc-x11)
    echo "Connect with:  vncviewer localhost:15901"
    echo "XFCE desktop is served via guest x11vnc (forwarded from host:15901 -> guest:5901)"
    echo "  (QEMU display: -vga virtio -display gtk for local render; x11vnc inside for remote)"
    qemu-system-x86_64 \
      "${QEMU_ACCEL[@]}" \
      -smp "$SMP" -m "$MEM" \
      -vga virtio -display gtk \
      -device virtio-keyboard-pci -device virtio-tablet-pci \
      -serial "file:$SERIAL_LOG" \
      -cdrom "$ISO" -boot d \
      -netdev user,id=net0,hostfwd=tcp:127.0.0.1:15901-:5901 \
      -device virtio-net-pci,netdev=net0
    ;;
  spice)
    echo "SPICE window will open"
    qemu-system-x86_64 \
      "${QEMU_ACCEL[@]}" \
      -smp "$SMP" -m "$MEM" \
      -vga qxl -display spice-app \
      -device virtio-keyboard-pci -device virtio-tablet-pci \
      -serial "file:$SERIAL_LOG" \
      -cdrom "$ISO" -boot d \
      -netdev "$NETDEV" -device virtio-net-pci,netdev=net0
    ;;
  cirrus)
    qemu-system-x86_64 \
      "${QEMU_ACCEL[@]}" \
      -smp "$SMP" -m "$MEM" \
      -vga cirrus -display gtk \
      -device virtio-keyboard-pci -device virtio-tablet-pci \
      -serial "file:$SERIAL_LOG" \
      -cdrom "$ISO" -boot d \
      -netdev "$NETDEV" -device virtio-net-pci,netdev=net0
    ;;
  virtio)
    qemu-system-x86_64 \
      "${QEMU_ACCEL[@]}" \
      -smp "$SMP" -m "$MEM" \
      -vga virtio -display gtk \
      -device virtio-keyboard-pci -device virtio-tablet-pci \
      -serial "file:$SERIAL_LOG" \
      -cdrom "$ISO" -boot d \
      -netdev "$NETDEV" -device virtio-net-pci,netdev=net0
    ;;
  *)
    echo "Usage: $0 [display|vnc|vnc-x11|spice|cirrus|virtio] [iso-path] [ram-mb] [cpus]"
    exit 1
    ;;
esac
