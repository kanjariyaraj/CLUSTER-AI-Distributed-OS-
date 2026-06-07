# Phase 8: Advanced Distributed Inference (Tensor Splitting)

## Goal
Enable AIDOS to run large AI models (e.g., 70B parameters) that exceed the RAM of a single node by splitting the workload at the tensor level.

## Tasks
- [ ] **Task 8.1: RPC Backend Integration**
  - Integrate `llama.cpp`'s RPC (Remote Procedure Call) backend into the AIDOS layer.
- [ ] **Task 8.2: Memory Management**
  - Implement a check to determine total available cluster RAM.
  - Automatically split the model layers across nodes based on available memory.
- [ ] **Task 8.3: Optimization of Latency**
  - Optimize the network protocol to handle high-speed tensor data transfers between nodes.

## Deliverables
- Support for running models 2x–4x larger than the largest single node's RAM.
- Benchmark report showing distributed RAM utilization.
