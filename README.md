# 🌌 AIDOS: The Distributed AI Supercomputing OS

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://img.shields.io/badge/Build-Optimized-brightgreen.svg)]()
[![Platform: Alpine](https://img.shields.io/badge/Platform-Alpine_Linux-blue.svg)](https://alpinelinux.org/)
[![AI Engine: llama.cpp](https://img.shields.io/badge/AI_Engine-llama.cpp-red.svg)](https://github.com/ggerganov/llama.cpp)

> **"AIDOS transforms low-end machines into a distributed AI supercomputer with zero setup."**

AIDOS (Artificial Intelligence Distributed Operating System) is a hyper-minimalist, high-performance OS designed to solve one of the biggest problems in modern tech: **The Hardware Barrier for AI.**

By pooling the resources of multiple "low-end" machines (old laptops, desktops, or even small servers), AIDOS creates a virtual supercomputer capable of running massive Large Language Models (LLMs) that would normally require expensive enterprise GPUs.

---

## 🌟 Why AIDOS?

| Benefit | Description |
| :--- | :--- |
| **💰 Zero Cost** | Reuse your old hardware instead of buying $5,000 GPUs. |
| **🚀 Distributed Power** | Split a single AI prompt across 5 machines to get 5x faster results. |
| **🛡️ Total Privacy** | Run everything locally. Your data never leaves your private network. |
| **⚡ Hyper-Light** | Sub-100MB OS footprint. Every CPU cycle is dedicated to AI. |

---

## 🛠️ Core Technology Stack

AIDOS is built from the ground up for performance. No bloat, just power.

- **OS Core:** Custom-built **Alpine Linux** distribution.
- **Inference Engine:** Highly optimized **C++ llama.cpp** (GGUF support).
- **Communication:** Low-latency **TCP Sockets** for real-time node coordination.
- **API Surface:** Lightweight **C++ REST Server** for easy integration.
- **Boot System:** Hybrid **Fast-Boot** kernel with pre-emptive scheduling.

---

## ⚙️ How It Works (The 6-Stage Process)

AIDOS operates through a unique distributed workflow:

1.  **Node Discovery:** When a device boots AIDOS, it automatically broadcasts its presence to the local network.
2.  **Resource Mapping:** The Controller node identifies the CPU cores and RAM available on each joined device.
3.  **Model Partitioning:** Large AI models are strategically split into "shards" across different machines.
4.  **Distributed Inference:** When a prompt arrives, compute tasks are sent to all nodes simultaneously.
5.  **Result Aggregation:** The Controller gathers the partial results and reconstructs the final AI response.
6.  **Dynamic Load Balancing:** If one node slows down, the system automatically reroutes tasks to keep the cluster fast.

---

## 🏗️ System Architecture & Directory Design

We follow a strict "Clean System" design. The entire AIDOS environment lives in `/opt/aidos/`:

```bash
/opt/aidos/
 ├── api_server      # 🌐 The REST interface for external apps
 ├── node_server     # 💻 The local engine running on each machine
 ├── controller      # 🧠 The "Brain" that coordinates the cluster
 ├── llama.cpp/      # 🏎️ Optimized inference binaries
 ├── models/         # 📁 Your GGUF model library
 └── scripts/        # 🛠️ System health & update tools
```

---

## 🗺️ The Roadmap to Excellence

| Milestone | Status | Details |
| :--- | :--- | :--- |
| **Phase 1: Foundation** | ✅ | Automated Alpine rootfs generation pipeline. |
| **Phase 2: AI Core** | ✅ | Native `llama.cpp` integration with hardware acceleration. |
| **Phase 3: Connect** | 🏗️ | Implementation of the high-speed REST API server. |
| **Phase 4: Orchestrate** | 📅 | Multi-node resource monitoring & task assignment. |
| **Phase 5: Scale** | 📅 | Seamless cluster expansion (Plug-and-Compute). |
| **Phase 6: Optimize** | 📅 | Kernel tuning for < 5s boot times and 0% idle CPU. |

---

## 🚀 Getting Started

### 1. Build your OS
```bash
sudo ./build_rootfs.sh
```

### 2. Boot & Query
Once running, simply send a prompt to the cluster:
```bash
curl http://aidos-cluster/generate \
  -H "Content-Type: application/json" \
  -d '{"prompt": "How do I build a cluster?", "max_tokens": 100}'
```

---

## 💡 The Future: The Global Compute Mesh
Our ultimate goal is to create a decentralized **AI Compute Marketplace**. Imagine a world where anyone can contribute their idle CPU power to a global mesh, earning rewards while helping researchers and developers run the world's most advanced AI models for free.

---

## 🤝 Contributing
AIDOS is an open-source project. We welcome developers, system architects, and AI enthusiasts to help us build the future of distributed computing.

1.  Fork the repo
2.  Create your feature branch
3.  Commit your changes
4.  Push to the branch
5.  Open a Pull Request

---

## ⚖️ License
Licensed under the [MIT License](LICENSE). Built with ❤️ for the open-source community.
