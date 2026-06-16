#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
ISO_DIR="$PROJECT_DIR/iso_build"
OUT_DIR="$PROJECT_DIR/out"
ROOTFS_DIR="$OUT_DIR/rootfs"
ROOTFS_TAR="$OUT_DIR/rootfs.tar.gz"
INITRAMFS_FILE="$ISO_DIR/boot/initramfs-aidos.gz"
KERNEL_TYPE="${KERNEL_TYPE:-virt}"
KERNEL_PKG="/tmp/linux-${KERNEL_TYPE}.apk"
KERNEL_PKG_DIR="/tmp/linux-${KERNEL_TYPE}-pkg"
MODULES_DIR="$OUT_DIR/modules"
ALPINE_MIRROR="https://dl-cdn.alpinelinux.org/alpine"

echo "=========================================="
echo "  AIDOS ISO Builder (kernel: $KERNEL_TYPE)"
echo "  Custom kernel: ${CUSTOM_KERNEL_DIR:-"(none, using Alpine stock)"}"
echo "=========================================="

if [ ! -f "$ROOTFS_TAR" ]; then
    echo "ERROR: $ROOTFS_TAR not found. Run build_rootfs.sh first."
    exit 1
fi

rm -rf "$ISO_DIR/boot" "$ISO_DIR/isolinux"
mkdir -p "$ISO_DIR/boot" "$ISO_DIR/isolinux" "$MODULES_DIR"

if [ -n "$CUSTOM_KERNEL_DIR" ]; then
    echo "[1/5] Using custom kernel from $CUSTOM_KERNEL_DIR..."
    KERNEL_IMG="$CUSTOM_KERNEL_DIR/boot/vmlinuz-aidos"
    if [ ! -f "$KERNEL_IMG" ]; then
        echo "ERROR: Custom kernel image not found at $KERNEL_IMG"
        exit 1
    fi
    KERNEL_VER=$(ls "$CUSTOM_KERNEL_DIR/lib/modules/" | head -1)
    if [ -z "$KERNEL_VER" ]; then
        echo "ERROR: No kernel modules found in $CUSTOM_KERNEL_DIR/lib/modules/"
        exit 1
    fi
    cp "$KERNEL_IMG" "$ISO_DIR/boot/vmlinuz-${KERNEL_TYPE}"
    echo "  Kernel version: $KERNEL_VER (custom)"
else
    echo "[1/5] Downloading ${KERNEL_TYPE} kernel package..."
    if [ ! -f "$KERNEL_PKG" ]; then
        wget -q "${ALPINE_MIRROR}/v3.19/main/x86_64/linux-${KERNEL_TYPE}-6.6.142-r0.apk" -O "$KERNEL_PKG"
    fi
    rm -rf "$KERNEL_PKG_DIR"
    mkdir -p "$KERNEL_PKG_DIR"
    tar -xzf "$KERNEL_PKG" -C "$KERNEL_PKG_DIR" 2>/dev/null
    KERNEL_VER=$(cat "$KERNEL_PKG_DIR/usr/share/kernel/${KERNEL_TYPE}/kernel.release")
    echo "  Kernel version: $KERNEL_VER"

    cp "$KERNEL_PKG_DIR/boot/vmlinuz-${KERNEL_TYPE}" "$ISO_DIR/boot/vmlinuz-${KERNEL_TYPE}"
fi

echo "[2/5] Extracting boot modules for initramfs..."
MODS_DIR="$MODULES_DIR/lib/modules/$KERNEL_VER"
mkdir -p "$MODS_DIR"

# Determine module source directory
if [ -n "$CUSTOM_KERNEL_DIR" ]; then
    MOD_SRC="$CUSTOM_KERNEL_DIR/lib/modules/$KERNEL_VER"
else
    MOD_SRC="$KERNEL_PKG_DIR/lib/modules/$KERNEL_VER"
fi

# Only include modules needed to detect CD-ROM, mount ISO 9660, and drive display
# (no loop module needed - virt kernel lacks it)
for mod in squashfs isofs sr_mod cdrom ata_generic sd_mod virtio_blk virtio_scsi e1000 virtio_net virtio_dma_buf virtio-gpu; do
    src=$(find "$MOD_SRC" -name "${mod}.ko.gz" -o -name "${mod}.ko" | head -1)
    if [ -n "$src" ]; then
        dest="$MODS_DIR/$(echo $src | sed "s|$MOD_SRC/||")"
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
        if echo "$dest" | grep -q '\.gz$'; then
            gunzip -f "$dest"
        fi
        echo "  + ${mod}.ko"
    fi
done

# Determine modules parent dir for dep files
if [ -n "$CUSTOM_KERNEL_DIR" ]; then
    MOD_PARENT="$CUSTOM_KERNEL_DIR"
else
    MOD_PARENT="$KERNEL_PKG_DIR"
fi

cp "$MOD_SRC/modules.dep" "$MODS_DIR/"
cp "$MOD_SRC/modules.alias" "$MODS_DIR/" 2>/dev/null || true
cp "$MOD_SRC/modules.symbols" "$MODS_DIR/" 2>/dev/null || true

echo "[3/5] Extracting rootfs to ISO staging..."
rm -rf "$ROOTFS_DIR"
mkdir -p "$ROOTFS_DIR"
tar -xzf "$ROOTFS_TAR" -C "$ROOTFS_DIR"

# Copy all kernel modules into rootfs (for the running system)
mkdir -p "$ROOTFS_DIR/lib/modules"
cp -r "$MOD_SRC" "$ROOTFS_DIR/lib/modules/" 2>/dev/null || true

# Check if extlinux.conf exists (from fs-skel) and verify the extlinux path
# Alpine uses extlinux on disk installs, not needed for ISO boot
echo "  Rootfs prepared: $(du -sh "$ROOTFS_DIR" | cut -f1)"

echo "[4/5] Building custom initramfs..."
INITRAMFS_DIR=$(mktemp -d)

mkdir -p "$INITRAMFS_DIR/bin" "$INITRAMFS_DIR/dev" "$INITRAMFS_DIR/etc" \
         "$INITRAMFS_DIR/proc" "$INITRAMFS_DIR/sys" "$INITRAMFS_DIR/newroot" \
         "$INITRAMFS_DIR/mnt" "$INITRAMFS_DIR/sbin" "$INITRAMFS_DIR/lib"

cp "$ROOTFS_DIR/bin/busybox" "$INITRAMFS_DIR/bin/"
cp "$ROOTFS_DIR/lib/ld-musl-x86_64.so.1" "$INITRAMFS_DIR/lib/"
cp "$ROOTFS_DIR/lib/libc.musl-x86_64.so.1" "$INITRAMFS_DIR/lib/"

# Copy boot kernel modules into initramfs
mkdir -p "$INITRAMFS_DIR/lib/modules"
cp -r "$MODULES_DIR/lib/modules/$KERNEL_VER" "$INITRAMFS_DIR/lib/modules/"
cp "$MOD_SRC/modules.builtin" "$INITRAMFS_DIR/lib/modules/$KERNEL_VER/" 2>/dev/null || true
cp "$MOD_SRC/modules.builtin.modinfo" "$INITRAMFS_DIR/lib/modules/$KERNEL_VER/" 2>/dev/null || true

mkdir -p "$INITRAMFS_DIR/etc/modprobe.d"

# Create essential device nodes for early boot (before devtmpfs mount)
# Use cpio with device nodes since /tmp may be nodev
( cd "$INITRAMFS_DIR" && \
  echo "Shyam@123" | sudo -S mknod -m 622 dev/console c 5 1 2>/dev/null; \
  echo "Shyam@123" | sudo -S mknod -m 666 dev/null c 1 3 2>/dev/null; \
  echo "Shyam@123" | sudo -S mknod -m 666 dev/zero c 1 5 2>/dev/null )

cat << 'INITSCRIPT' > "$INITRAMFS_DIR/init"
#!/bin/busybox sh

export PATH=/bin:/sbin:/usr/bin:/usr/sbin

echo "AIDOS: Mounting essential filesystems..."
/bin/busybox mount -t proc proc /proc
/bin/busybox mount -t sysfs sysfs /sys
/bin/busybox mount -t devtmpfs devtmpfs /dev
/bin/busybox mount -t tmpfs tmpfs /run 2>/dev/null || true

echo "AIDOS: Loading kernel modules..."
/bin/busybox depmod -a 2>/dev/null
/bin/busybox modprobe cdrom 2>/dev/null || true
/bin/busybox modprobe sr_mod 2>/dev/null || true
/bin/busybox modprobe isofs 2>/dev/null || true
/bin/busybox modprobe squashfs 2>/dev/null || true
/bin/busybox modprobe ata_generic 2>/dev/null || true
/bin/busybox modprobe sd_mod 2>/dev/null || true
/bin/busybox modprobe virtio_blk 2>/dev/null || true
/bin/busybox modprobe virtio_scsi 2>/dev/null || true
/bin/busybox modprobe e1000 2>/dev/null || true
/bin/busybox modprobe virtio_net 2>/dev/null || true
/bin/busybox modprobe virtio_dma_buf 2>/dev/null || true
/bin/busybox modprobe virtio-gpu 2>/dev/null || true

/bin/busybox sleep 3

echo "AIDOS: Searching for boot media..."
ROOTFS_SRC=""

for dev in /dev/sr0 /dev/sr1 /dev/sda /dev/sdb /dev/sdc /dev/vda /dev/vdb /dev/xvda /dev/xvdb; do
    if [ -b "$dev" ]; then
        echo "  Checking $dev..."
        /bin/busybox mount -t iso9660 -o ro "$dev" /mnt 2>/dev/null && {
            if [ -x "/mnt/bin/busybox" ] || [ -f "/mnt/etc/alpine-release" ]; then
                ROOTFS_SRC="$dev"
                echo "AIDOS: Found rootfs on $dev"
                break
            fi
            /bin/busybox umount /mnt 2>/dev/null || true
        }
    fi
done

# Found the ISO - now copy rootfs to tmpfs (writable)
if [ -n "$ROOTFS_SRC" ]; then
    # ISO may already be mounted from the detection loop
    if ! /bin/busybox mountpoint -q /mnt; then
        echo "AIDOS: Mounting ISO..."
        /bin/busybox mount -t iso9660 -o ro "$ROOTFS_SRC" /mnt
    else
        echo "AIDOS: ISO already mounted"
    fi

    echo "AIDOS: Creating writable rootfs in RAM..."
    /bin/busybox mount -t tmpfs -o rw,nosuid,dev tmpfs /newroot

    echo "AIDOS: Copying rootfs to RAM (this may take a moment)..."
    # Copy all files from ISO root (excluding boot and isolinux dirs)
    for item in /mnt/*; do
        name=$(/bin/busybox basename "$item")
        case "$name" in
            boot|isolinux|rootfs-boot) ;;
            *) /bin/busybox cp -a "$item" /newroot/ || true ;;
        esac
    done
    # Also copy rootfs-boot contents if present
    [ -d "/mnt/rootfs-boot" ] && /bin/busybox cp -r /mnt/rootfs-boot/* /newroot/boot/ 2>/dev/null || true

    echo "AIDOS: Creating device nodes in new root..."
    /bin/busybox mkdir -p /newroot/dev
    /bin/busybox mknod -m 600 /newroot/dev/console c 5 1 2>/dev/null || true
    /bin/busybox mknod -m 666 /newroot/dev/ttyS0 c 4 64 2>/dev/null || true
    /bin/busybox mknod -m 666 /newroot/dev/null c 1 3 2>/dev/null || true
    /bin/busybox mknod -m 666 /newroot/dev/zero c 1 5 2>/dev/null || true
    /bin/busybox mknod -m 644 /newroot/dev/urandom c 1 9 2>/dev/null || true

    INIT_PATH=""
    if [ -x "/newroot/sbin/init" ]; then
        INIT_PATH="/sbin/init"
    elif [ -x "/newroot/bin/busybox" ]; then
        echo "AIDOS: /sbin/init not found, using /bin/busybox as init"
        INIT_PATH="/bin/busybox"
    else
        echo "AIDOS ERROR: no init found after copy!"
        /bin/busybox ls -la /newroot/ 2>/dev/null || true
        exec /bin/busybox sh
    fi

    echo "AIDOS: Mounting pseudo-fs in new root..."
    /bin/busybox mount -t proc proc /newroot/proc 2>/dev/null || true
    /bin/busybox mount -t sysfs sysfs /newroot/sys 2>/dev/null || true
    /bin/busybox mount --move /dev /newroot/dev 2>/dev/null || \
        /bin/busybox mount -t devtmpfs devtmpfs /newroot/dev 2>/dev/null || true
    /bin/busybox mount --move /run /newroot/run 2>/dev/null || true

    echo "AIDOS: Switching to root filesystem (init=$INIT_PATH)..."
    exec /bin/busybox switch_root /newroot "$INIT_PATH"
fi

echo "AIDOS ERROR: Could not find boot media!"
echo "AIDOS: Dropping to emergency shell..."
echo "  Block devices:"
/bin/busybox ls -la /dev/sr* /dev/sd* /dev/vd* /dev/xvd* 2>/dev/null || echo "  (none)"
exec /bin/busybox sh
INITSCRIPT

chmod +x "$INITRAMFS_DIR/init"

(cd "$INITRAMFS_DIR" && find . | cpio -H newc -o --quiet | gzip -9) > "$INITRAMFS_FILE"
rm -rf "$INITRAMFS_DIR"
echo "  Initramfs created: $(du -h "$INITRAMFS_FILE" | cut -f1)"

echo "[5/5] Staging ISO and generating image..."
# Extract rootfs directly into ISO directory
# Files at ISO root will be visible when mounted, allowing direct copy to tmpfs
for item in "$ROOTFS_DIR"/*; do
    name=$(basename "$item")
    [ "$name" = "boot" ] && continue
    cp -r "$item" "$ISO_DIR/" 2>/dev/null || true
done
cp -r "$ROOTFS_DIR/boot" "$ISO_DIR/rootfs-boot" 2>/dev/null || true

echo "  Rootfs staged on ISO"

# Find isolinux files
ISOLINUX_BIN=$(find /usr -name isolinux.bin | head -n 1)
LDLINUX_C32=$(find /usr -name ldlinux.c32 | head -n 1)
if [ -n "$ISOLINUX_BIN" ] && [ -n "$LDLINUX_C32" ]; then
    cp "$ISOLINUX_BIN" "$ISO_DIR/isolinux/"
    cp "$LDLINUX_C32" "$ISO_DIR/isolinux/"
fi

cat <<EOF > "$ISO_DIR/isolinux/isolinux.cfg"
DEFAULT aidos
LABEL aidos
  KERNEL /boot/vmlinuz-${KERNEL_TYPE}
  APPEND initrd=/boot/initramfs-aidos.gz console=tty0 console=ttyS0,115200
LABEL aidos-serial
  KERNEL /boot/vmlinuz-${KERNEL_TYPE}
  APPEND initrd=/boot/initramfs-aidos.gz console=ttyS0,115200
LABEL aidos-debug
  KERNEL /boot/vmlinuz-${KERNEL_TYPE}
  APPEND initrd=/boot/initramfs-aidos.gz console=tty0 console=ttyS0,115200 debug
EOF

rm -f "$OUT_DIR/aidos.iso"
xorriso -as mkisofs -l -J -R -V "AIDOS_AI" \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -b isolinux/isolinux.bin -c isolinux/boot.cat \
    --mbr-force-bootable -partition_cyl_align all \
    -o "$OUT_DIR/aidos.iso" "$ISO_DIR"

# Keep kernel APK cached for faster rebuilds
# rm -f "$KERNEL_PKG"
rm -rf "$KERNEL_PKG_DIR" "$MODULES_DIR" "$ROOTFS_DIR"

echo ""
echo "=========================================="
echo "  AIDOS ISO Build Complete!"
echo "  Output: $OUT_DIR/aidos.iso"
echo "  Size:   $(du -h "$OUT_DIR/aidos.iso" | cut -f1)"
echo "  Kernel: $KERNEL_VER"
echo "=========================================="
