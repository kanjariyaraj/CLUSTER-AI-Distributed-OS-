#!/bin/bash
set -e

# Setup directories
ISO_DIR="iso_build"
mkdir -p "$ISO_DIR/boot"
mkdir -p "$ISO_DIR/isolinux"

# Download Kernel and Initrd from Alpine v3.19
echo "Downloading Alpine boot components..."
wget -q "https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/x86_64/netboot/vmlinuz-virt" -O "$ISO_DIR/boot/vmlinuz-virt"
wget -q "https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/x86_64/netboot/initramfs-virt" -O "$ISO_DIR/boot/initramfs-virt"

# Find isolinux files on the host
ISOLINUX_BIN=$(find /usr -name isolinux.bin | head -n 1)
LDLINUX_C32=$(find /usr -name ldlinux.c32 | head -n 1)

if [ -n "$ISOLINUX_BIN" ] && [ -n "$LDLINUX_C32" ]; then
    echo "Found bootloader components: $ISOLINUX_BIN"
    cp "$ISOLINUX_BIN" "$ISO_DIR/isolinux/"
    cp "$LDLINUX_C32" "$ISO_DIR/isolinux/"
else
    echo "Warning: isolinux.bin not found on host."
fi

# Create isolinux configuration
cat <<EOF > "$ISO_DIR/isolinux/isolinux.cfg"
DEFAULT aidos
LABEL aidos
  KERNEL /boot/vmlinuz-virt
  APPEND initrd=/boot/initramfs-virt modules=loop,squashfs,sd-mod,usb-storage quiet cpufreq.default_governor=performance nohz_full=1-3
EOF

# Note: In a real Alpine ISO, the rootfs is typically inside a modloop squashfs.
# For this demo, we are generating the ISO structure for VirtualBox.

echo "Creating ISO image..."
xorriso -as mkisofs -l -J -R -V "AIDOS_AI" \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -b isolinux/isolinux.bin -c isolinux/boot.cat \
    -o out/aidos.iso "$ISO_DIR"

echo "ISO generated: out/aidos.iso"
