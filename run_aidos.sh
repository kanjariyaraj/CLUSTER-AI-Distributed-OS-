#!/bin/bash
# Run AIDOS ISO in QEMU
# Usage: ./run_aidos.sh [display|vnc|spice] [iso-path] [ram-mb] [cpus]

MODE="${1:-display}"
ISO="${2:-out/aidos.iso}"
MEM="${3:-4096}"
SMP="${4:-4}"

SERIAL_LOG="/tmp/aidos-serial-$$.log"

# Kill leftover serial listeners
pkill -f "aidos-serial-.*\.log" 2>/dev/null || true

PORTS="hostfwd=tcp::8080-:8080,hostfwd=tcp::8081-:8081,hostfwd=tcp::8082-:8082,hostfwd=tcp::8083-:8083,hostfwd=tcp::50052-:50052,hostfwd=tcp::5901-:5901"
NETDEV="user,id=net0,$PORTS"

# Check for conflicting port forwards
for port in 8080 8081 8082 8083 50052 5901; do
  if ss -tlnp "sport = :$port" 2>/dev/null | grep -q .; then
    echo "WARNING: Port $port already in use"
  fi
done

echo "Launching AIDOS ISO: $ISO"
echo " RAM: ${MEM}MB | CPUs: $SMP | Mode: $MODE"
echo " Serial log: $SERIAL_LOG"
echo " Ports: 8080(API) 8081(Node) 8082(Ctrl) 8083(Market) 50052(RPC)"
echo ""

case "$MODE" in
  display|gtk)
    qemu-system-x86_64 \
      -enable-kvm -machine q35 -cpu host \
      -smp "$SMP" -m "$MEM" \
      -vga std -display gtk \
      -serial "file:$SERIAL_LOG" \
      -cdrom "$ISO" -boot d \
      -netdev "$NETDEV" -device virtio-net-pci,netdev=net0
    ;;
  vnc)
    echo "Connect: vncviewer localhost:5900"
    qemu-system-x86_64 \
      -enable-kvm -machine q35 -cpu host \
      -smp "$SMP" -m "$MEM" \
      -vga std -display vnc=:0 \
      -serial "file:$SERIAL_LOG" \
      -cdrom "$ISO" -boot d \
      -netdev "$NETDEV" -device virtio-net-pci,netdev=net0
    ;;
  vnc-x11)
    echo "Two VNC servers:"
    echo "  5900 - QEMU boot/console (virtio-gpu)"
    echo "  5901 - x11vnc (XFCE desktop inside VM)"
    echo "  Start desktop: telnet localhost 5920, login, run: start-desktop.sh"
    qemu-system-x86_64 \
      -enable-kvm -machine q35 -cpu host \
      -smp "$SMP" -m "$MEM" \
      -vga virtio -display vnc=:0 \
      -serial "file:$SERIAL_LOG" \
      -cdrom "$ISO" -boot d \
      -netdev "$NETDEV" -device virtio-net-pci,netdev=net0
    ;;
  spice)
    echo "SPICE window will open"
    qemu-system-x86_64 \
      -enable-kvm -machine q35 -cpu host \
      -smp "$SMP" -m "$MEM" \
      -vga qxl -display spice-app \
      -serial "file:$SERIAL_LOG" \
      -cdrom "$ISO" -boot d \
      -netdev "$NETDEV" -device virtio-net-pci,netdev=net0
    ;;
  cirrus)
    qemu-system-x86_64 \
      -enable-kvm -machine q35 -cpu host \
      -smp "$SMP" -m "$MEM" \
      -vga cirrus -display gtk \
      -serial "file:$SERIAL_LOG" \
      -cdrom "$ISO" -boot d \
      -netdev "$NETDEV" -device virtio-net-pci,netdev=net0
    ;;
  virtio)
    qemu-system-x86_64 \
      -enable-kvm -machine q35 -cpu host \
      -smp "$SMP" -m "$MEM" \
      -vga virtio -display gtk \
      -serial "file:$SERIAL_LOG" \
      -cdrom "$ISO" -boot d \
      -netdev "$NETDEV" -device virtio-net-pci,netdev=net0
    ;;
  *)
    echo "Usage: $0 [display|vnc|vnc-x11|spice|cirrus|virtio] [iso-path] [ram-mb] [cpus]"
    exit 1
    ;;
esac
