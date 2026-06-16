#!/bin/bash
set -e
cd "$(dirname "$0")"
CXX=${CXX:-g++}
FLAGS="-std=c++17 -O2 -static -I.."
echo "Building AIDOS services..."
for src in node_server.cpp controller.cpp api_server.cpp marketplace.cpp; do
    bin="${src%.cpp}"
    echo "  $src -> $bin"
    $CXX $FLAGS "$src" -o "$bin"
    strip --strip-all "$bin" 2>/dev/null || true
done
echo "Done. Binaries: $(ls -lh node_server controller api_server marketplace | awk '{print $NF, $5}')"
