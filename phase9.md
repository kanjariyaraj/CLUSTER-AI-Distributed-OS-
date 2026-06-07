# Phase 9: AI Compute Marketplace

## Goal
Create a decentralized system where users can "rent out" their idle CPU/GPU time to others in exchange for credits or tokens.

## Tasks
- [ ] **Task 9.1: Credit System Implementation**
  - Develop a basic ledger to track compute contributions (TFLOPS provided).
  - Implement a user authentication layer (API keys).
- [ ] **Task 9.2: Secure Task Execution**
  - Use `cgroups` or `namespaces` to sandbox AI execution on donor nodes.
  - Implement encrypted task payloads to protect user data.
- [ ] **Task 9.3: Web Dashboard**
  - Create a dashboard to show "Total Cluster Power" and "Personal Earnings."

## Deliverables
- Prototype marketplace server.
- Web-based management console for compute donors.
