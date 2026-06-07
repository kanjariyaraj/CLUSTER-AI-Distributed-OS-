# 🌌 AIDOS: The Distributed AI Supercomputing OS

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://img.shields.io/badge/Build-Optimized-brightgreen.svg)]()
[![Platform: Alpine](https://img.shields.io/badge/Platform-Alpine_Linux-blue.svg)](https://alpinelinux.org/)
[![AI Engine: llama.cpp](https://img.shields.io/badge/AI_Engine-llama.cpp-red.svg)](https://github.com/ggerganov/llama.cpp)
[![Arch: x86_64/ARM64](https://img.shields.io/badge/Arch-x86__64%20%7C%20ARM64-blueviolet.svg)]()
[![Stability: Prototype](https://img.shields.io/badge/Stability-Prototype-orange.svg)]()

> **"AIDOS transforms low-end machines into a distributed AI supercomputer with zero setup."**

AIDOS (Artificial Intelligence Distributed Operating System) is a hyper-minimalist, high-performance Linux distribution based on Alpine Linux. It is designed to solve the **Hardware Barrier for AI** by pooling the collective CPU and RAM of multiple "low-end" machines (old laptops, Raspberry Pis, old Android phones) into a single virtual supercomputer.

---

## 🏗️ System Architecture (Deep Dive)

AIDOS operates on a **Controller-Node** architecture with a zero-config discovery layer.

### 1. The Gateway Layer (API Server)
*   **Purpose:** The entry point for all user requests.
*   **Tech:** C++17, `cpp-httplib`, `nlohmann/json`.
*   **Port:** 8080
*   **Function:** Receives standard JSON prompts and forwards them to the Cluster Controller.

### 2. The Orchestration Layer (Controller)
*   **Purpose:** The "Brain" of the cluster.
*   **Port:** 8082
*   **Features:**
    *   **UDP Discovery:** Automatically detects new nodes on the network via port 8888.
    *   **Health Monitoring:** Tracks node load and removes timed-out nodes.
    *   **Load Balancing:** Distributes tasks to the least-busy nodes.
    *   **Marketplace Reporting:** Logs work completion to the ledger.

### 3. The Compute Layer (Node Server & RPC)
*   **Purpose:** Where the actual AI inference happens.
*   **Ports:** 8081 (Task API), 50052 (llama.cpp RPC).
*   **Features:**
    *   **Static AI Engine:** Uses a custom-built, statically linked `llama.cpp`.
    *   **Heartbeat Thread:** Broadcasts UDP packets every 5 seconds for auto-discovery.
    *   **Tensor Splitting:** Uses RPC backends to pool RAM across multiple physical machines.

### 4. The Incentive Layer (Marketplace)
*   **Purpose:** Monetizing idle compute power.
*   **Port:** 8083
*   **Features:**
    *   **Ledger System:** Tracks "AIDOS Credits" earned by each node ID.
    *   **Web Dashboard:** A dark-themed real-time UI to monitor cluster power and individual earnings.

---

## 🚀 The 10-Phase Development Lifecycle

AIDOS was built through a systematic 10-stage engineering process:

| Phase | Milestone | Core Innovation | Status |
| :--- | :--- | :--- | :--- |
| **1** | **Foundation** | Automated Alpine rootfs generation with `fakeroot`. | ✅ |
| **2** | **AI Core** | Static `llama.cpp` compilation for Musl/Alpine. | ✅ |
| **3** | **API Gateway** | C++ REST implementation for seamless model access. | ✅ |
| **4** | **Mesh** | Basic Controller-Node communication protocol. | ✅ |
| **5** | **Optimization** | Kernel tuning for low-latency and performance governor. | ✅ |
| **6** | **ISO Build** | Packaging a bootable Live-OS for VirtualBox/Hardware. | ✅ |
| **7** | **Discovery** | Zero-config networking with UDP Heartbeats. | ✅ |
| **8** | **Inference+** | Tensor Splitting via llama.cpp RPC for huge models. | ✅ |
| **9** | **Marketplace** | Real-time Credit Ledger and Web Dashboard. | ✅ |
| **10** | **Edge** | ARM64 Cross-compilation for Raspberry Pi/Mobile nodes. | ✅ |

---

## 🛠️ Build & Compilation (Technical Details)

AIDOS is designed for maximum portability. All binaries are **statically linked** against `musl` libc.

### x86_64 Build (Standard)
We use an Alpine Docker container to ensure binaries are compatible with the minimal target environment:
```bash
# Example Docker-based static build
g++ -O3 -static aidos_api/api_server.cpp -lpthread -o out/api_server
```

### ARM64 Cross-Compilation (Edge)
To support Raspberry Pis and Mobile devices, we use a specialized cross-compilation pipeline:
*   **Toolchain:** `aarch64-linux-musl` inside Docker.
*   **Output:** Static binaries that run on any `aarch64` Alpine install.

---

## 📂 Project Structure

```text
.
├── aidos_api/          # Source code for API, Controller, Marketplace, Node
├── fs-skel/            # Custom filesystem overlay (binaries, boot configs)
├── llama.cpp_src/      # AI Engine source code
├── out/                # Build artifacts (ISO, Rootfs Tarballs)
├── phase1.md - 10.md   # Detailed logs of every development stage
├── TESTING_GUIDE.md    # Step-by-step manual for cluster validation
└── AIDOS_COMPLETE_GUIDE.md # Technical master manual
```

---

## 🚦 Getting Started

### 1. Deployment (VirtualBox)
1.  Download `out/aidos.iso`.
2.  Create a VM with 2GB+ RAM (Type: Other Linux 64-bit).
3.  Mount the ISO and Boot.

### 2. Usage
```bash
# 1. Download a model (inside the VM)
/opt/aidos/scripts/manage_models.sh download

# 2. Query the cluster API
curl http://localhost:8080/generate -d "What is the capital of France?"

# 3. View the Marketplace Dashboard
# Navigate to http://<VM_IP>:8083 in your browser
```

---

## 🔮 Future Roadmap (V2.0)
*   **Encrypted Compute:** Using TEE (Trusted Execution Environments) to protect data on untrusted nodes.
*   **Mobile App:** One-click "Join Cluster" button for Android/iOS devices.
*   **Automatic Sharding:** Dynamic reallocation of model layers based on real-time network latency.

---

## ❓ FAQ

**Q: Does it support NVIDIA GPUs?**
A: Current version is CPU-only, optimized for AVX2/AVX512. GPU support is planned for Phase 11.

**Q: Can I run this on my old Raspberry Pi?**
A: Yes! Use the ARM64 binaries and follow the guide in `phase10.md`.

**Q: Is it really zero-config?**
A: Yes. As long as machines are on the same local network (subnet), the UDP Discovery (Phase 7) will automatically form the cluster.

---

## ⚖️ License
Licensed under the [MIT License](LICENSE). Built for the democratization of AI.
