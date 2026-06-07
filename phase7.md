# Phase 7: Real-Time Cluster Discovery

## Goal
Eliminate manual IP configuration by allowing new AIDOS nodes to automatically find and join the cluster via the local network.

## Tasks
- [ ] **Task 7.1: UDP Broadcast Implementation**
  - Develop a "Heartbeat" mechanism where nodes broadcast their presence.
  - Implement a listener in the Controller to detect these broadcasts.
- [ ] **Task 7.2: Dynamic Node Registry**
  - Create an in-memory database in the Controller to manage active/inactive nodes.
  - Implement health checks (pinging nodes every 30 seconds).
- [ ] **Task 7.3: Load-Aware Distribution**
  - Update the Node Server to report CPU/RAM usage in the heartbeat.
  - Update the Controller to send tasks to the least-busy nodes.

## Deliverables
- Updated `controller` and `node_server` with auto-discovery support.
- CLI command: `aidos cluster list` to show active nodes.
