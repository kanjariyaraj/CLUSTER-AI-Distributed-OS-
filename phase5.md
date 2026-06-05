# Phase 5: System Optimization (Kernel & Boot)

## Goal
Optimize the Alpine Linux kernel and boot parameters for low-latency AI performance.

## Tasks
- [ ] **Task 5.1: Kernel Configuration**
  - Enable Preemptible kernel.
  - Enable Low latency scheduling.
  - Disable unused drivers.
- [ ] **Task 5.2: Boot Loader Configuration**
  - Edit `/boot/extlinux.conf`.
  - Add `cpufreq.default_governor=performance` and `nohz_full=1-3`.
- [ ] **Task 5.3: Performance Benchmarking**
  - Compare AI inference speed before and after optimizations.

## Deliverables
- Optimized kernel build.
- Updated boot configuration files.
