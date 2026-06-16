#!/bin/sh
# AIDOS Performance Benchmark
# Measures AI inference speed using llama.cpp's built-in benchmark.
#
# Usage:
#   benchmark.sh                    # Quick CPU benchmark (no model needed)
#   benchmark.sh /path/to/model.gguf   # Real model inference benchmark

GLIBC_LD="/opt/aidos/glibc/lib/ld-linux-x86-64.so.2"
GLIBC_LIB="/opt/aidos/glibc/lib:/opt/aidos/ollama/lib"
LLAMA_BENCH="/opt/aidos/llama.cpp/llama-server"
OLLAMA_BIN="/opt/aidos/ollama/bin/ollama"

echo "=========================================="
echo "  AIDOS Performance Benchmark"
echo "=========================================="
echo ""
echo "System info:"
echo "  Kernel: $(uname -r)"
echo "  CPU: $(grep 'model name' /proc/cpuinfo | head -1 | sed 's/.*: //')"
echo "  Cores: $(nproc)"
echo "  RAM: $(free -h | grep Mem | awk '{print $2}')"
echo "  Preempt: $(grep -c CONFIG_PREEMPT=y /proc/config.gz 2>/dev/null || echo 'check /proc/config')"
echo "  Timer Hz: $(getconf CLK_TCK 2>/dev/null || echo 'N/A')"
echo ""

# Test 1: CPU prime number computation (scheduler latency test)
echo "[1/4] Scheduler latency test (prime computation)..."
cat > /tmp/bench_prime.c << 'EOF'
#include <stdio.h>
#include <time.h>
#include <pthread.h>

void* work(void* arg) {
    volatile long count = 0;
    for (int i = 2; i < 50000; i++) {
        int is_prime = 1;
        for (int j = 2; j * j <= i; j++) {
            if (i % j == 0) { is_prime = 0; break; }
        }
        if (is_prime) count++;
    }
    return NULL;
}

int main() {
    pthread_t threads[8];
    struct timespec start, end;
    clock_gettime(CLOCK_MONOTONIC, &start);
    for (int i = 0; i < 8; i++)
        pthread_create(&threads[i], NULL, work, NULL);
    for (int i = 0; i < 8; i++)
        pthread_join(threads[i], NULL);
    clock_gettime(CLOCK_MONOTONIC, &end);
    double elapsed = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / 1e9;
    printf("  %d threads, %.3f seconds\n", 8, elapsed);
    return 0;
}
EOF
gcc -O2 -pthread /tmp/bench_prime.c -o /tmp/bench_prime 2>/dev/null && /tmp/bench_prime || echo "  (compile failed, skipping)"
rm -f /tmp/bench_prime /tmp/bench_prime.c

# Test 2: Memory bandwidth (simple sequential read)
echo ""
echo "[2/4] Memory bandwidth test..."
cat > /tmp/bench_mem.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define SIZE (256 * 1024 * 1024)  // 256 MB

int main() {
    char* buf = malloc(SIZE);
    if (!buf) { printf("  (malloc failed)\n"); return 1; }
    memset(buf, 0xAA, SIZE);

    struct timespec start, end;
    volatile long sum = 0;

    clock_gettime(CLOCK_MONOTONIC, &start);
    for (int pass = 0; pass < 4; pass++) {
        for (size_t i = 0; i < SIZE; i += 64)
            sum += buf[i];
    }
    clock_gettime(CLOCK_MONOTONIC, &end);
    double elapsed = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / 1e9;
    double bw = (4.0 * SIZE / 1024 / 1024 / 1024) / elapsed;
    printf("  Sequential read: %.2f GB/s (%.3fs)\n", bw, elapsed);
    free(buf);
    return 0;
}
EOF
gcc -O2 /tmp/bench_mem.c -o /tmp/bench_mem 2>/dev/null && /tmp/bench_mem || echo "  (compile failed, skipping)"
rm -f /tmp/bench_mem /tmp/bench_mem.c

# Test 3: llama.cpp inference benchmark (if model provided)
if [ -n "$1" ] && [ -f "$1" ]; then
    echo ""
    echo "[3/4] llama.cpp inference benchmark..."
    echo "  Model: $1"
    $GLIBC_LD --library-path $GLIBC_LIB $LLAMA_BENCH --model "$1" --benchmark 1 --numa 2>&1 | head -20 || echo "  (benchmark failed)"
else
    echo ""
    echo "[3/4] llama.cpp benchmark: SKIP (no model provided)"
    echo "  Usage: $0 /path/to/model.gguf"
fi

# Test 4: Ollama API latency
echo ""
echo "[4/4] AIDOS service latency test..."
for svc in api_server:8080 controller:8082 node_server:8081 marketplace:8083; do
    name="${svc%:*}"
    port="${svc#*:}"
    start=$(date +%s%N)
    resp=$(wget -q -T 2 -O /dev/null "http://localhost:$port/" 2>&1)
    end=$(date +%s%N)
    elapsed=$(( (end - start) / 1000000 ))
    if [ "$resp" != "" ] && [ $elapsed -lt 5000 ]; then
        echo "  $name: ${elapsed}ms"
    else
        echo "  $name: unreachable"
    fi
done

echo ""
echo "=========================================="
echo "  Benchmark complete!"
echo "=========================================="
