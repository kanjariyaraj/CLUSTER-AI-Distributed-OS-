#!/bin/sh
# AIDOS Cluster Model Launcher
# Queries the controller for available RPC endpoints and launches llama-server
# with tensor splitting across all available cluster nodes.
#
# Usage:
#   aidos-run-model.sh <model_path> [model_size_gb]
#
# Examples:
#   aidos-run-model.sh /opt/aidos/models/qwen2.5-72b.gguf 48
#   aidos-run-model.sh /models/llama-70b.gguf
#   aidos-run-model.sh --launch-only  # just print the command, don't execute

CONTROLLER="localhost:8082"
LLAMA_SERVER="/opt/aidos/llama.cpp/llama-server"
GLIBC_LD="/opt/aidos/glibc/lib/ld-linux-x86-64.so.2"
GLIBC_LIB="/opt/aidos/glibc/lib:/opt/aidos/ollama/lib"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <model_path> [model_size_gb]"
    echo ""
    echo "Queries the AIDOS controller for cluster nodes and launches"
    echo "llama-server with tensor splitting across all available nodes."
    echo ""
    echo "Examples:"
    echo "  $0 /models/qwen2.5-72b.gguf 48"
    echo "  $0 /models/llama-70b.gguf"
    exit 1
fi

MODEL_PATH="$1"
MODEL_SIZE="${2:-0}"

echo "AIDOS Cluster Model Launcher"
echo "=============================="
echo "Model: $MODEL_PATH"
echo "Model size: ${MODEL_SIZE}GB"
echo ""

# Fetch cluster nodes
echo "[1/3] Querying controller for cluster nodes..."
NODES=$(curl -s http://$CONTROLLER/nodes)
NODE_COUNT=$(echo "$NODES" | grep -o '"id"' | wc -l)
if [ "$NODE_COUNT" -eq 0 ]; then
    echo "ERROR: No nodes found. Is the controller running?"
    exit 1
fi
echo "  Found $NODE_COUNT nodes in cluster"

# Check cluster memory
echo "[2/3] Checking cluster memory..."
MEM=$(curl -s http://$CONTROLLER/cluster_memory)
TOTAL_MEM=$(echo "$MEM" | grep -o '"available_memory_gb":[0-9.]*' | cut -d: -f2)
echo "  Total available cluster memory: ${TOTAL_MEM}GB"

if [ "$MODEL_SIZE" != "0" ]; then
    if [ "$(echo "$TOTAL_MEM < $MODEL_SIZE" | bc -l 2>/dev/null)" = "1" ]; then
        echo "ERROR: Model requires ${MODEL_SIZE}GB but only ${TOTAL_MEM}GB available"
        exit 1
    fi
    echo "  Model fits in cluster memory: YES"
fi

# Get RPC endpoints
echo "[3/3] Building RPC endpoint list..."
RPC_JSON=$(curl -s http://$CONTROLLER/rpc_endpoints)
RPC_URLS=$(echo "$RPC_JSON" | grep -o '"rpc://[^"]*"' | tr '\n' ',' | sed 's/,$//' | sed 's/"//g')

if [ -z "$RPC_URLS" ]; then
    echo "WARNING: No RPC endpoints found. Running locally only."
fi

echo ""
echo "  RPC endpoints: $RPC_URLS"
echo ""

# Build the command
CMD="$GLIBC_LD --library-path $GLIBC_LIB $LLAMA_SERVER"
CMD="$CMD --model $MODEL_PATH"
CMD="$CMD --host 0.0.0.0"
CMD="$CMD --port 8080"
CMD="$CMD --no-mmap"
CMD="$CMD -ngl 99"

if [ -n "$RPC_URLS" ]; then
    # Remove rpc:// prefix for llama.cpp --rpc flag format
    RPC_FLAG=$(echo "$RPC_URLS" | sed 's/rpc:\/\///g')
    CMD="$CMD --rpc $RPC_FLAG"
    echo "Strategy: tensor split across $NODE_COUNT nodes"
else
    echo "Strategy: single node"
fi

echo ""
echo "  Command:"
echo "  $CMD"
echo ""

# Launch
echo "Starting llama-server..."
exec $CMD
