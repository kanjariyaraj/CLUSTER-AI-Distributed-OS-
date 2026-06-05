# Phase 1: Environment Setup & Base Rootfs Generation

## Goal
Establish a reliable build pipeline for creating the AIDOS Alpine Linux rootfs.

## Tasks
- [ ] **Task 1.1: Verify Build Environment**
  - Ensure `apk`, `rsync`, and `tar` are available.
  - Test `alpine-make-rootfs` script.
- [ ] **Task 1.2: Define Base Configuration**
  - Specify Alpine version (latest-stable).
  - Identify core packages needed for the base system.
- [ ] **Task 1.3: Create Initial Build Script**
  - Automate the calling of `./alpine-make-rootfs`.
  - Handle output directory and logging.
- [ ] **Task 1.4: Generate First Rootfs**
  - Run the build script.
  - Verify the resulting rootfs structure.

## Deliverables
- `build_rootfs.sh`: Script to generate the base rootfs.
- `rootfs.tar.gz`: Initial base system archive.
