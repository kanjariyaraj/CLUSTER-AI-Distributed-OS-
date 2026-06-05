# Phase 3: API Server Implementation

## Goal
Develop a lightweight C++ HTTP server to expose the AI engine's functionality via a REST API.

## Tasks
- [ ] **Task 3.1: Library Selection**
  - Choose a minimal C++ HTTP library (e.g., `cpp-httplib`).
- [ ] **Task 3.2: Implement /generate Endpoint**
  - Create the API handler that interfaces with `llama.cpp`.
  - Handle JSON input and output.
- [ ] **Task 3.3: Server Configuration**
  - Implement port configuration and logging.
  - Ensure the server runs as a background process.
- [ ] **Task 3.4: Integration Testing**
  - Verify `curl localhost:8080/generate -d "Hello AI"` works within the rootfs.

## Deliverables
- `api_server` binary in `/opt/aidos/api_server`.
- API documentation (endpoints and parameters).
