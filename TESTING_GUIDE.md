# AIDOS Testing & Future Roadmap

This document provides a concise step-by-step guide to testing the AIDOS distributed AI system and outlines the vision for future development.

## 🧪 1. Deployment (VirtualBox / Bare Metal)
1. **Create VM:** 64-bit Linux, 2GB+ RAM.
2. **Mount ISO:** Load `out/aidos.iso` into the optical drive.
3. **Boot:** The system will boot into the optimized Alpine kernel.
4. **Login:** Use `root` (no password by default).

## 📥 2. Model Management
Before running inference, you need a GGUF model:
```bash
# Use the built-in management script
/opt/aidos/scripts/manage_models.sh download
```
*Models are stored in `/opt/aidos/models/`.*

## 🚀 3. Testing Local Inference (Single Node)
Verify that the AI engine works locally:
```bash
cd /opt/aidos/llama.cpp/
./llama -m /opt/aidos/models/llama-2-7b-chat.Q4_K_M.gguf -p "What is AIDOS?"
```

## 🌐 4. Testing the Distributed API
The system starts three services on boot:
* **API Server (8080):** Entry point for users.
* **Controller (8082):** Dynamic workload balancer.
* **Node Server (8081):** Compute worker (sends UDP heartbeats).

### 🔍 Phase 7: Verification (Auto-Discovery)
1. **List Nodes:**
   ```bash
   curl localhost:8082/nodes
   ```
2. **Watch for Auto-Join:**
   * Boot a second VM.
   * Run the command above on VM-1. You will see VM-2 appear automatically in the list.
3. **Test Load Balancing:**
   * Send multiple requests to `localhost:8080/generate`.
   * The Controller will distribute tasks to any node that has announced itself.

**Test command:**
```bash
curl localhost:8080/generate -d "Hello AI"
```
*Flow: User -> API (8080) -> Controller (8082) -> Node (8081) -> Result.*

## 🔗 5. Multi-Node Cluster Setup
To test true distribution:
1. Boot 2 separate VMs (Node A and Node B).
2. Edit `/opt/aidos/controller/controller` config (or use env vars in future) to add Node B's IP.
3. Run inference on Node A; Node B will handle part of the computation.

---

## 🔮 Future Roadmap & Features

### 🛠️ Phase 7: Real-Time Cluster Discovery
* **Auto-Join:** New nodes on the network automatically announce themselves via UDP broadcast.
* **Health Monitoring:** Controller tracks node CPU/RAM usage to optimize task splitting.

### ⚡ Phase 8: Advanced Distributed Inference
* **Tensor Splitting:** Split large models across multiple nodes' RAM.
* **Pipeline Parallelism:** Process different layers of the LLM on different machines.

### 💰 Phase 9: AI Compute Marketplace
* **Incentivization:** Earn credits for contributing idle CPU time to the AIDOS network.
* **Privacy Layer:** Encrypted task distribution to ensure data remains secure across untrusted nodes.

### 📱 Phase 10: Mobile & Edge Integration
* **ARM Support:** Build for Raspberry Pi and old Android phones to create "Edge Supercomputers."
* **Web UI:** A clean dashboard at port 80 to manage the cluster and chat with models.
