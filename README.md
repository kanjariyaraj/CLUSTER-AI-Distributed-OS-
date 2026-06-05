# AIDOS: Distributed AI Supercomputing OS

> **"AIDOS transforms low-end machines into a distributed AI supercomputer with zero setup."**

AIDOS is a lightweight, Alpine Linux-based operating system designed to democratize AI compute. By leveraging distributed systems and optimized C++ backends, AIDOS allows clusters of machines to pool their resources for high-performance AI inference.

---

## 🚀 The Vision

Modern AI requires massive compute power often out of reach for individual users or small organizations. AIDOS changes this by:
- **Distributed Execution:** Splitting AI workloads across multiple devices.
- **Minimalist OS:** Using Alpine Linux as a base for sub-100MB footprint.
- **Plug-and-Play:** Bootable ISOs that join a compute cluster automatically.

---

## 🔥 Key Features & Advantages

### 1. Distributed AI Inference
The core strength of AIDOS is its ability to turn a local network of computers into a single powerful inference engine. It uses `llama.cpp` at its core, optimized for CPU execution.

### 2. Ultra-Lightweight (Alpine Based)
By building on Alpine Linux, AIDOS ensures that every bit of RAM and CPU cycle goes towards AI computation, not OS overhead.
- **Base OS:** Alpine Linux
- **Kernel:** Optimized for low-latency scheduling.
- **Disk Footprint:** Highly compressed rootfs.

### 3. Native C++ Performance
The entire stack—from the API server to the cluster controller—is written in C/C++ to ensure maximum throughput and minimum latency.

### 4. Zero-Config Clustering
Future versions aim to support a "Cluster Mode" where devices automatically discover each other and start sharing compute tasks.

---

## 🏗️ System Architecture

| Layer | Technology |
| :--- | :--- |
| **OS Layer** | Alpine Linux (Hardened & Minimized) |
| **Core Layer** | C++17 / POSIX Shell |
| **AI Engine** | `llama.cpp` (GGUF Support) |
| **API Layer** | Lightweight C++ HTTP Server |
| **Cluster Layer** | TCP Sockets / Distributed Task Scheduler |
| **Build System** | `alpine-make-rootfs` |

### System Structure
Files are organized in `/opt/aidos/` for a clean, immutable-style system:
```text
/opt/aidos/
 ├── api_server      # Handles REST requests
 ├── node_server     # Manages local compute resources
 ├── controller      # Orchestrates the cluster
 ├── llama.cpp/      # AI Inference engine
 ├── models/         # Local GGUF models
 └── scripts/        # System management utilities
```

---

## 🗺️ Project Roadmap

| Phase | Description | Status |
| :--- | :--- | :--- |
| **Phase 1** | **Base OS:** Pipeline for Alpine rootfs generation. | ✅ Done |
| **Phase 2** | **AI Engine:** `llama.cpp` integration and optimization. | ✅ Done |
| **Phase 3** | **API Layer:** REST endpoint for AI generation. | 🏗️ In Progress |
| **Phase 4** | **Node Server:** Resource monitoring and local task management. | 📅 Planned |
| **Phase 5** | **Controller:** Global cluster orchestration logic. | 📅 Planned |
| **Phase 6** | **Networking:** Low-latency TCP socket communication. | 📅 Planned |
| **Phase 7** | **Optimization:** Kernel tuning and boot-speed improvements. | 📅 Planned |
| **Phase 8** | **UX:** Automated ISO build and installer. | 📅 Planned |
| **Phase 9** | **Demo:** Real-world multi-node AI cluster showcase. | 🚀 Future |

---

## 🛠️ Usage

### API Interaction
Once booted, AIDOS exposes a simple REST API:
```bash
curl localhost:8080/generate -d '{"prompt": "Explain Quantum Physics", "temp": 0.7}'
```

### Cluster Command (Future)
```bash
aidos cluster join --secret my-network-key
```

---

## 💡 The Future: Decentralized Compute Marketplace
Beyond local clusters, the long-term goal for AIDOS is an **AI Compute Sharing Network**. Idle devices worldwide could join a decentralized marketplace, providing compute power in exchange for tokens or reciprocal access, effectively creating a "Global AI Supercomputer."

---

## ⚖️ License
This project is licensed under the [MIT License](LICENSE). 
Portions of the build scripts are derived from the original `alpine-make-rootfs` project.
