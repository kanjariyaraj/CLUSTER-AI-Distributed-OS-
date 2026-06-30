#!/bin/bash
set -e

# Configuration
ALPINE_BRANCH=${ALPINE_BRANCH:-v3.19}
ALPINE_MIRROR=${ALPINE_MIRROR:-http://dl-cdn.alpinelinux.org/alpine}
DEST_DIR="out/rootfs"
DEST_TAR="out/rootfs.tar.gz"
# Minimal XFCE desktop - individual packages, NO thunar/tumbler (avoids webkit2gtk, ffmpeg bloat)
XFCE_PKGS="xorg-server xfce4-session xfwm4 xfce4-panel xfdesktop xfce4-settings xfce4-power-manager xfce4-terminal lightdm lightdm-gtk-greeter dbus dbus-openrc dbus-x11 polkit elogind desktop-file-utils shared-mime-info adwaita-icon-theme ttf-dejavu x11vnc xinit xf86-video-qxl xf86-video-vesa xf86-video-fbdev mesa-dri-gallium xdotool"
# mpv for boot animation playback on framebuffer (DRM/KMS)
BOOT_PKGS="mpv"
PACKAGES="curl bash openrc alpine-conf gcompat libstdc++ libgcc ${XFCE_PKGS} ${BOOT_PKGS}"

# Create output directory
mkdir -p out

export APK="./apk.static"

echo "Building AIDOS Alpine Rootfs..."
echo "Branch: $ALPINE_BRANCH"
echo "Mirror: $ALPINE_MIRROR"

# Run alpine-make-rootfs with a post-install script
# that sets the root password for console login
./alpine-make-rootfs \
    --branch "$ALPINE_BRANCH" \
    --mirror-uri "$ALPINE_MIRROR" \
    --packages "$PACKAGES" \
    --fs-skel-dir "fs-skel" \
    --script-chroot \
    "$DEST_TAR" \
    - <<'SCRIPT'
echo "Setting root password..."
echo "root:aidos" | /bin/busybox chpasswd
echo "root password set to: aidos"

echo "Ensuring /sbin/init symlink exists..."
[ -L "/sbin/init" ] || ln -sf /bin/busybox /sbin/init
ls -la /sbin/init

echo "Creating default user 'aidos'..."
adduser -D -s /bin/bash aidos
echo "aidos:aidos" | chpasswd
adduser aidos wheel
adduser aidos video
echo "Default user 'aidos' created (password: aidos)"

echo "Setting up ollama directories..."
mkdir -p /home/aidos/.ollama/models
chown -R aidos:aidos /home/aidos

echo "Configuring system services..."
rc-update add sysfs sysinit
rc-update add procfs sysinit
rc-update add devfs sysinit
rc-update add mdev boot
rc-update add dbus default
rc-update add elogind default
rc-update add local default
rc-update add boot-animation sysinit

echo "Setting Xorg setuid root for non-root display access..."
chown root:root /usr/libexec/Xorg 2>/dev/null
chmod u+s /usr/libexec/Xorg 2>/dev/null || \
chown root:root /usr/lib/xorg/Xorg 2>/dev/null || true
chmod u+s /usr/lib/xorg/Xorg 2>/dev/null || \
chown root:root /usr/bin/Xorg 2>/dev/null || true
chmod u+s /usr/bin/Xorg 2>/dev/null || echo "WARNING: Could not set Xorg setuid"
# Verify
ls -la /usr/libexec/Xorg /usr/lib/xorg/Xorg /usr/bin/Xorg 2>/dev/null || true

echo "Xorg will autodetect the modesetting driver (no /etc/X11/xorg.conf needed)."
echo "The modesetting driver works with virtio-gpu DRM/KMS via /dev/dri/card0."
echo "For fbdev fallback, install xf86-video-fbdev and create xorg.conf."

echo "Setting up lightdm auto-login for aidos user..."
mkdir -p /etc/lightdm
cat > /etc/lightdm/lightdm.conf << 'LIGHTDM'
[Seat:*]
autologin-user=aidos
autologin-user-timeout=0
user-session=xfce
greeter-session=lightdm-gtk-greeter
LIGHTDM

echo "Creating XFCE desktop entry for AIDOS cluster tools..."
mkdir -p /usr/share/applications
cat > /usr/share/applications/aidos-dashboard.desktop << 'DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=AIDOS Cluster Dashboard
Comment=AI Distributed Operating System dashboard
Exec=xdg-open http://localhost:8083
Icon=computer
Terminal=false
Categories=Network;
DESKTOP

echo "Setting up XDG autostart for AIDOS services..."
mkdir -p /etc/xdg/autostart
cat > /etc/xdg/autostart/aidos-services.desktop << 'AUTOSTART'
[Desktop Entry]
Type=Application
Name=AIDOS Services
Exec=/etc/local.d/aidos.start
NoDisplay=true
X-GNOME-Autostart-enabled=true
AUTOSTART

echo "Purging unnecessary bloat packages to keep ISO lean..."
apk del --purge tumbler thunar gnome-keyring webkit2gtk 2>/dev/null || true
apk del --purge ffmpeg gst-plugins-bad gst-plugins-base gstreamer 2>/dev/null || true
# apk del --purge mesa-dri-gallium mesa-va-gallium mesa-vulkan-ati mesa-vulkan-intel 2>/dev/null || true
apk del --orphans 2>/dev/null || true
SCRIPT

echo "Build complete: $DEST_TAR"
