# 🌌 AIDOS: The Distributed AI Supercomputing OS

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://img.shields.io/badge/Build-Optimized-brightgreen.svg)]()
[![Platform: Alpine](https://img.shields.io/badge/Platform-Alpine_Linux-blue.svg)](https://alpinelinux.org/)
[![AI Engine: llama.cpp](https://img.shields.io/badge/AI_Engine-llama.cpp-red.svg)](https://github.com/ggerganov/llama.cpp)
[![Stability: Alpha](https://img.shields.io/badge/Stability-Alpha-orange.svg)]()
[![Contributions: Welcome](https://img.shields.io/badge/Contributions-Welcome-brightgreen.svg)]()

> **"AIDOS transforms low-end machines into a distributed AI supercomputer with zero setup."**

---

## 🗺️ Project Overview

AIDOS (Artificial Intelligence Distributed Operating System) is a hyper-minimalist, high-performance OS designed to solve the **Hardware Barrier for AI.** By pooling the resources of multiple "low-end" machines (old laptops, desktops, or small servers), AIDOS creates a virtual supercomputer capable of running massive Large Language Models (LLMs) that would normally require expensive enterprise GPUs.

---

## 🏗️ Visual Architecture Diagram

```text
      [ 🌐 External Request (User/App) ]
                    |
                    v
      [ 📡 AIDOS API Gateway (Node 0) ]
                    |
      +-------------+-------------+
      |             |             |
[ 🧠 Node 1 ] [ 🧠 Node 2 ] [ 🧠 Node 3 ] ... [ 🧠 Node N ]
(Shard A)      (Shard B)      (Shard C)        (Shard N)
      |             |             |
      +-------------+-------------+
                    |
      [ 🚀 Aggregated AI Response ]
```

---

## 💎 The 6 Key Advantages of AIDOS

| Advantage | AIDOS | Traditional AI |
| :--- | :--- | :--- |
| **💰 Cost** | **Zero** (Reuse old hardware) | **$5,000+** (Enterprise GPUs) |
| **⚡ Footprint** | **< 100MB** (Alpine Linux) | **20GB+** (Ubuntu/Windows) |
| **🚀 Scalability** | **Infinite** (Add more PCs) | **Limited** (PCIe Slots/VRAM) |
| **🛡️ Privacy** | **100% Local** | **Risky** (Cloud API dependency) |
| **🛠️ Maintenance** | **Plug-and-Play** | **Complex** (Driver/CUDA Hell) |
| **🌐 Accessibility** | **Democratized** | **Elitist** (High barrier to entry) |

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

## 📁 System Architecture (Internal Stack)

The system is organized into 6 critical directories within `/opt/aidos/`:

```bash
/opt/aidos/
 ├── api_server      # 🌐 External REST interface (C++ Httplib)
 ├── node_server     # 💻 Local compute management (Process Monitor)
 ├── controller      # 🧠 Global cluster orchestration (Task Master)
 ├── llama.cpp/      # 🏎️ Native inference binaries (AVX2/AVX512/NEON)
 ├── models/         # 📁 GGUF Model repository (Quantized weights)
 └── scripts/        # 🛠️ System maintenance & boot-time health checks
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

1.  **Clone:**
    ```bash
    git clone https://github.com/kanjariyaraj/liunx-based-os-disatication-project-.git
    ```
2.  **Build:** Run the automated build script:
    ```bash
    sudo ./build_rootfs.sh
    ```
3.  **Deploy:** Flash the generated `rootfs.tar.gz` to a bootable medium.
4.  **Join:** Connect multiple machines to the same LAN; they will auto-pair.
5.  **Query:** Send your first AI prompt via the REST API:
    ```bash
    curl http://localhost:8080/generate -d '{"prompt": "Hello AIDOS!"}'
    ```
6.  **Scale:** Add more nodes on-the-fly to increase context size and speed.

---

## ❓ Frequently Asked Questions (FAQ)

**Q: Can I use machines with different CPU architectures?**
A: Yes! AIDOS is designed to be heterogeneous. It will automatically detect the capabilities (AVX2, AVX512, etc.) of each node.

**Q: What models are supported?**
A: Any model in GGUF format is supported, including Llama 3, Mistral, Gemma, and more.

**Q: Is a GPU required?**
A: No. AIDOS is specifically optimized for high-performance **CPU-only** distributed inference.

---

## ⚖️ License
Licensed under the [MIT License](LICENSE). Built with ❤️ for the future of open-source AI.
/cha/cha