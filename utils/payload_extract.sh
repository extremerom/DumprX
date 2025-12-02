#!/bin/bash
# Wrapper script for Python-based payload extractor
# Usage: payload_extract.sh <input_file> <output_dir> [workers]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INPUT_FILE="$1"
OUTPUT_DIR="${2:-.}"
WORKERS="${3:-$(nproc --all)}"

if [ -z "$INPUT_FILE" ]; then
    echo "Usage: $0 <input_file> <output_dir> [workers]"
    exit 1
fi

python3 "${SCRIPT_DIR}/dumprx_unpacker.py" payload -t bin -i "$INPUT_FILE" -o "$OUTPUT_DIR" -T "$WORKERS"
