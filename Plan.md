Step 16: Kernel Config

make menuconfig

Enable:

- Preemptible kernel
- Low latency scheduling
- Disable unused drivers

---

Step 17: Boot Optimization

Edit:

/boot/extlinux.conf

Add:

cpufreq.default_governor=performance
nohz_full=1-3

---

📦 PHASE 7: PREINSTALLED SYSTEM STRUCTURE

/opt/aidos/
 ├── api_server
 ├── node_server
 ├── controller
 ├── llama.cpp/
 ├── models/
 └── scripts/

---

Step 18: Auto Start Services

/etc/local.d/aidos.start

./node_server &
./api_server &

---

🎯 PHASE 8: USER EXPERIENCE

User Steps:

1. Download ISO
2. Install OS
3. Boot system

---

Usage:

API Call

curl localhost:8080/generate -d "Hello AI"

---

Cluster Mode (Future CLI)

aidos cluster run llama

---

🔥 PHASE 9: DEMO PLAN (CRITICAL)

Demo Setup:

- 2–3 laptops connected

---

Demo Flow:

1. Run model on single device → slow
2. Run cluster → faster
3. Show:
   - CPU usage split
   - Faster response

---

💣 BONUS FEATURE (ADVANCED)

AI Compute Sharing Network

- Idle devices join cluster
- Distributed AI execution
- Future: decentralized compute marketplace

---

🚀 FINAL STACK

Layer| Tech
OS| Alpine Linux
Core| C/C++
AI Engine| llama.cpp
API| C++ HTTP server
Cluster| TCP sockets
Build| Alpine mkimage

---

⏱️ EXECUTION TIMELINE

Phase| Time
ISO Build| 3h
AI Engine| 3h
API Server| 3h
Cluster System| 6h
Optimization| 3h
Demo Setup| 2h

👉 Total: ~20 hours

---

🧠 FINAL NOTES

- Focus on working demo over perfection
- Distributed system = main USP
- Keep system minimal but powerful
- Preinstalled + plug-and-play = judge winning factor

---

🏁 FINAL PITCH LINE

«“AIDOS transforms low-end machines into a distributed AI supercomputer with zero setup.”»

---

END OF PLAN
