# Phase 10: Mobile & Edge Integration

## Goal
Expand the cluster to include non-x86 hardware, such as ARM-based Raspberry Pis and old Android phones, to maximize the pool of "forgotten" compute.

## Tasks
- [x] **Task 10.1: ARM64 Build Pipeline**
  - Setup cross-compilation for AIDOS services for `aarch64`.
  - Established Docker-based ARM64 build environment.
- [ ] **Task 10.2: Mobile "Worker" App**
  - Develop a lightweight Android service that runs a Node Server in the background.
  - Optimize for thermal throttling and battery management.
- [ ] **Task 10.3: Edge Orchestration**
  - Add support for mixed-architecture clusters (x86 + ARM).

## Deliverables
- AIDOS ARM64 bootable image (Raspberry Pi).
- Android `.apk` for joining the cluster as a compute node.
