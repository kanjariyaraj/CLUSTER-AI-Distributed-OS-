#!/bin/bash
set -e

# Configuration
ALPINE_BRANCH=${ALPINE_BRANCH:-v3.19}
ALPINE_MIRROR=${ALPINE_MIRROR:-http://dl-cdn.alpinelinux.org/alpine}
DEST_DIR="out/rootfs"
DEST_TAR="out/rootfs.tar.gz"
PACKAGES="curl bash"
export APK_OPTS="--no-scripts --no-progress --verbose"

# Create output directory
mkdir -p out

export APK="./apk.static"

echo "Building AIDOS Alpine Rootfs..."
echo "Branch: $ALPINE_BRANCH"
echo "Mirror: $ALPINE_MIRROR"

# Run alpine-make-rootfs
# We don't use fakeroot here because alpine-make-rootfs calls apk.static
# which we want to run under fakeroot.
# Actually, running the whole script under fakeroot is better.
./alpine-make-rootfs \
    --branch "$ALPINE_BRANCH" \
    --mirror-uri "$ALPINE_MIRROR" \
    --packages "$PACKAGES" \
    --fs-skel-dir "fs-skel" \
    "$DEST_TAR"

echo "Build complete: $DEST_TAR"
