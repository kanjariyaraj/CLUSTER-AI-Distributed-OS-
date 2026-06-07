# AIDOS: Master Technical Guide & Testing Manual

## 1. Project Overview
AIDOS (AI Distributed Operating System) is a specialized Alpine Linux distribution designed to transform low-end hardware into a high-performance, distributed AI supercomputer. It removes the complexity of setting up AI environments by providing a plug-and-play bootable ISO.

---

## 2. System Architecture
The system consists of four primary layers:
1.  **OS Layer:** Minimal Alpine Linux (v3.23) with an optimized kernel.
2.  **Inference Layer:** `llama.cpp` (statically compiled) for local AI execution.
3.  **Service Layer:** Three custom C++ services using `httplib` and `nlohmann/json`.
4.  **Distribution Layer:** A Controller-Node architecture for workload sharing.

### Core Components:
*   **API Server (Port 8080):** Handles user requests (`/generate`).
*   **Controller (Port 8082):** Tracks available nodes via UDP discovery and distributes prompts.
*   **Node Server (Port 8081):** Listens for tasks and triggers the AI engine. Broadcasts UDP heartbeats for discovery.

---

## 3. How the ISO was Created (Step-by-Step)
...
### Step 5: Real-Time Cluster Discovery (Phase 7)
We implemented a zero-config networking layer:
*   **UDP Heartbeats:** Each node sends a JSON packet every 5 seconds to port 8888.
*   **Dynamic Registry:** The Controller maintains a live map of nodes. If a node fails to send a heartbeat for 15 seconds, it is automatically removed from the cluster.
*   **Discovery API:** A new endpoint `GET /nodes` allows users to see the real-time cluster state.

### Step 1: Base Rootfs Generation
Using the `alpine-make-rootfs` script, a base Alpine Linux environment was created. 
*   **Constraint:** To build without root privileges, we used `fakeroot` and modified the script to handle `apk` options correctly.
*   **Result:** A clean, minimal filesystem in `out/rootfs.tar.gz`.

### Step 2: Static Compilation (The Docker Method)
Because the host is Fedora/RH but the target is Alpine (Musl), we used an **Alpine Docker Container** to compile all binaries.
*   **llama.cpp:** Compiled with `-DLLAMA_OPENSSL=OFF` and `-static` flags to ensure it runs on any Alpine machine without missing `.so` files.
*   **Custom Services:** `api_server`, `node_server`, and `controller` were all compiled using `g++ -static` inside Docker to ensure 100% portability.

### Step 3: Filesystem Merging (`fs-skel`)
A "Skeleton" directory (`fs-skel`) was created containing:
*   **Service Binaries:** Moved to `/opt/aidos/`.
*   **Auto-start Scripts:** Created in `/etc/local.d/aidos.start`.
*   **Boot Config:** Optimized `extlinux.conf` placed in `/boot/`.
*   **Management:** `manage_models.sh` for model downloading.

### Step 4: ISO Generation
We used `xorriso` and `syslinux` to wrap the components:
1.  **Kernel/Initrd:** Downloaded from the official Alpine v3.19 netboot repository.
2.  **Bootloader:** Configured `isolinux` to point to the kernel and initrd.
3.  **Packaging:** `xorriso` combined the bootloader and the system files into `out/aidos.iso`.

---

## 4. ISO Internal File Map (Deep Detail)
When you mount the `aidos.iso`, this is the exact structure you will see:

```text
/
├── boot/
│   ├── vmlinuz-virt        # The optimized Alpine Kernel
│   └── initramfs-virt      # The RAM-based initial filesystem
├── isolinux/
│   ├── isolinux.bin        # BIOS bootloader
│   ├── isolinux.cfg        # Boot menu configuration
│   └── ldlinux.c32         # Syslinux module
└── (System Files via Rootfs)
    ├── etc/local.d/aidos.start     # Service auto-launch script
    ├── opt/aidos/
    │   ├── api_server/api_server   # Entry-point binary
    │   ├── controller/controller   # Load balancer binary
    │   ├── node_server/node_server # Compute worker binary
    │   ├── llama.cpp/              # AI Engine folder
    │   ├── models/                 # GGUF storage (empty on ISO)
    │   └── scripts/                # management tools
    └── boot/extlinux.conf          # System-level boot optimizations
```

---

## 5. How to Customize the ISO
If you want to add your own models or custom C++ code to the ISO before burning:

### Adding a Model pre-boot:
1.  Extract the `out/aidos_rootfs_v2.tar.gz`.
2.  Place your `.gguf` model in `opt/aidos/models/`.
3.  Re-pack the tarball.
4.  Run `./generate_iso.sh` to wrap the new filesystem into a new ISO.

### Modifying the AI Engine:
1.  Edit files in `aidos_api/`.
2.  Run the **Docker Build Command** (found in Section 3) to compile a new static binary.
3.  Replace the old binary in `fs-skel/opt/aidos/`.
4.  Re-generate the ISO.

---

## 6. Full Software Stack Reference
| Layer | Technology | Purpose |
| :--- | :--- | :--- |
| **Bootloader** | Syslinux / Isolinux | BIOS Boot & Menu |
| **Kernel** | Linux 6.6+ (virt) | Hardware abstraction |
| **Base OS** | Alpine Linux (Musl) | Ultra-minimal footprint |
| **AI Engine** | llama.cpp (Static) | CPU-optimized inference |
| **API Framework**| cpp-httplib | High-performance C++ Web Server |
| **JSON Parser**  | nlohmann/json | Data serialization |
| **Build System** | xorriso / Docker | Image creation & compilation |

---

## 7. How to Run (Deployment Guide)

### VirtualBox Setup:
1.  **New VM:** Name: `AIDOS_Node_1`, Type: `Linux`, Version: `Other Linux (64-bit)`.
2.  **Hardware:** 
    *   **RAM:** Minimum 2048 MB (4096 MB preferred).
    *   **Processors:** 2 CPUs minimum.
3.  **Storage:** 
    *   Add a Virtual Optical Drive and select `out/aidos.iso`.
4.  **Network:** Set to `Bridged Adapter` if you want to test multiple VMs communicating.
5.  **Start:** Hit "Start". The menu will show "AIDOS Alpine". Press Enter.

---

## 6. Deep Testing Instructions

### Level 1: OS Verification
Once booted, log in as `root`.
```bash
uname -a      # Verify optimized kernel
ls /opt/aidos # Verify all folders exist
ps aux        # Verify api_server, controller, and node_server are running
```

### Level 2: Model Management Test
```bash
# This downloads a 4GB model. Ensure you have internet in the VM.
/opt/aidos/scripts/manage_models.sh download
```

### Level 3: AI Engine Test (Local)
```bash
/opt/aidos/llama.cpp/llama -m /opt/aidos/models/*.gguf -p "AIDOS is" -n 20
```
*If text generates, the inference engine is working.*

### Level 4: API & Cluster Flow Test
Test the full software stack using a local loopback request:
```bash
curl -X POST http://localhost:8080/generate -d "Test Prompt"
```
**Expected Internal Flow:**
1.  **Port 8080 (API):** Receives "Test Prompt".
2.  **Port 8082 (Controller):** API sends prompt here. Controller decides which node to use.
3.  **Port 8081 (Node):** Controller sends task here. Node returns the result.
4.  **User:** Receives JSON response.

### Level 5: Multi-VM Cluster Test (Advanced)
1.  Boot **VM-1** (IP: 192.168.1.10) and **VM-2** (IP: 192.168.1.11).
2.  On **VM-1**, edit the Controller to include VM-2's IP.
3.  Send a request to **VM-1**.
4.  Watch the logs on **VM-2** (`ps` or redirect output to a log file) to see it handling the computation.

---

## 7. Troubleshooting
*   **No Boot:** Ensure "Enable EFI" is UNCHECKED in VirtualBox (we use BIOS/Syslinux).
*   **Slow Inference:** Check if "VT-x/AMD-V" is enabled in your BIOS/VirtualBox settings.
*   **Network Error:** Ensure the VM network is set to "Bridged" or "NAT" with port forwarding for 8080.
