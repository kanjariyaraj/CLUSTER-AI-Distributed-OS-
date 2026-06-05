# Phase 2: AI Engine Integration (llama.cpp)

## Goal
Incorporate `llama.cpp` into the AIDOS rootfs to provide the core AI capabilities.

## Tasks
- [ ] **Task 2.1: Setup Build Dependencies**
  - Add `build-base`, `cmake`, and `git` to the rootfs build process.
- [ ] **Task 2.2: Fetch and Compile llama.cpp**
  - Download the `llama.cpp` source code.
  - Compile it with optimizations for the target architecture.
- [ ] **Task 2.3: Integration into Rootfs**
  - Place binaries in `/opt/aidos/llama.cpp/`.
  - Ensure shared libraries (if any) are correctly linked.
- [ ] **Task 2.4: Model Management**
  - Create directory `/opt/aidos/models/`.
  - Implement a basic script to download/load models.

## Deliverables
- Compiled `llama.cpp` binaries within the rootfs.
- Directory structure for models.
