#!/bin/sh
set -e

MODEL_DIR="/opt/aidos/models"
DEFAULT_MODEL_URL="https://huggingface.co/TheBloke/Llama-2-7B-Chat-GGUF/resolve/main/llama-2-7b-chat.Q4_K_M.gguf"

download_model() {
    local url="${1:-$DEFAULT_MODEL_URL}"
    local filename=$(basename "$url")
    echo "Downloading model from $url..."
    curl -L "$url" -o "$MODEL_DIR/$filename"
    echo "Model downloaded to $MODEL_DIR/$filename"
}

list_models() {
    ls -lh "$MODEL_DIR"
}

case "$1" in
    download)
        download_model "$2"
        ;;
    list)
        list_models
        ;;
    *)
        echo "Usage: $0 {download [url]|list}"
        exit 1
        ;;
esac
