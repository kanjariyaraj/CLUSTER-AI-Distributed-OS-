# 🌌 AIDOS: The Distributed AI Supercomputing OS

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://img.shields.io/badge/Build-Optimized-brightgreen.svg)]()
[![Platform: Alpine](https://img.shields.io/badge/Platform-Alpine_Linux-blue.svg)](https://alpinelinux.org/)
[![AI Engine: llama.cpp](https://img.shields.io/badge/AI_Engine-llama.cpp-red.svg)](https://github.com/ggerganov/llama.cpp)

> **"AIDOS transforms low-end machines into a distributed AI supercomputer with zero setup."**

AIDOS (Artificial Intelligence Distributed Operating System) is a hyper-minimalist, high-performance OS designed to solve the **Hardware Barrier for AI.** By pooling the resources of multiple machines, AIDOS creates a virtual supercomputer for Large Language Models (LLMs).

---

## 💎 The 6 Key Advantages of AIDOS

| Advantage | Description |
| :--- | :--- |
| **1. 💰 Zero Capital Outlay** | Reclaim and reuse existing "obsolete" hardware instead of buying enterprise GPUs. |
| **2. 🚀 Linear Scalability** | Add nodes to the cluster to gain near-linear increases in inference speed and context capacity. |
| **3. 🛡️ Absolute Privacy** | Local-first architecture. Your data never touches the cloud or external servers. |
| **4. ⚡ Hyper-Efficiency** | Sub-100MB OS footprint ensures every clock cycle is dedicated to AI computation. |
| **5. 🛠️ C++ Native Speed** | Zero-overhead execution using optimized C++ binaries for the entire stack. |
| **6. 🌐 Global Mesh Future** | Built to scale from local LAN clusters to a decentralized global compute marketplace. |

---

## 🛠️ The 6 Core Technologies

1.  **OS Foundation:** A hardened, custom-stripped **Alpine Linux** for minimal latency.
2.  **Inference Engine:** Optimized **llama.cpp** with GGUF support for CPU-based AI.
3.  **Communication:** Ultra-low-latency **TCP/IP Sockets** for inter-node messaging.
4.  **API Gateway:** A high-performance **C++17 REST Server** (cpp-httplib).
5.  **Cluster Logic:** Custom **Distributed Task Scheduler** written in native C++.
6.  **Build Pipeline:** Integrated **Automated RootFS Generator** for reproducible builds.

---

## ⚙️ The 6-Stage Distributed Workflow

AIDOS orchestrates AI compute through a precise, 6-step lifecycle:

1.  **Discovery Phase:** New nodes broadcast heartbeat signals via UDP to join the active cluster.
2.  **Resource Audit:** The Controller node profiles every node's CPU architecture and available RAM.
3.  **Dynamic Sharding:** AI models are partitioned into optimal shards based on individual node capacity.
4.  **Parallel Execution:** Prompt tasks are distributed across the mesh for simultaneous processing.
5.  **Packet Synthesis:** The Controller reassembles the fragmented token streams into a coherent response.
6.  **Fault Tolerance:** If a node drops, the system instantly redistributes its shard to remaining nodes.

---

## 🏗️ System Architecture (The AIDOS Stack)

The system is organized into 6 critical directories within `/opt/aidos/`:

```bash
/opt/aidos/
 ├── api_server      # 🌐 External REST interface
 ├── node_server     # 💻 Local compute management
 ├── controller      # 🧠 Global cluster orchestration
 ├── llama.cpp/      # 🏎️ Native inference binaries
 ├── models/         # 📁 GGUF Model repository
 └── scripts/        # 🛠️ System maintenance & health
```

---

## 🗺️ The 6-Phase Roadmap to V1.0

| Milestone | Status | Objective |
| :--- | :--- | :--- |
| **Phase 1: Foundation** | ✅ | Automated Alpine rootfs generation pipeline. |
| **Phase 2: AI Core** | ✅ | Native `llama.cpp` integration with CPU optimizations. |
| **Phase 3: Gateway** | 🏗️ | Implementation of the C++ REST API and JSON handler. |
| **Phase 4: Mesh** | 📅 | Multi-node resource monitoring & task allocation. |
| **Phase 5: Elasticity** | 📅 | Seamless, hot-plug cluster expansion and rebalancing. |
| **Phase 6: Perfection** | 📅 | Kernel tuning for < 5s cold boot and peak optimization. |

---

## 🚀 Getting Started in 6 Minutes

1.  **Clone:** `git clone https://github.com/kanjariyaraj/liunx-based-os-disatication-project-.git`
2.  **Build:** Run `sudo ./build_rootfs.sh` to generate your system image.
3.  **Deploy:** Flash the image to a USB drive or boot it in a VM.
4.  **Join:** Power on your nodes; they will automatically form a cluster.
5.  **Query:** Send your first AI prompt via the REST API.
6.  **Scale:** Add more old PCs to see the inference speed increase!

---

## ⚖️ License
Licensed under the [MIT License](LICENSE). Built with ❤️ for the future of open AI.
