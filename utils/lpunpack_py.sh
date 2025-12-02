#!/bin/bash
# Wrapper script for Python-based lpunpack (super.img extractor)
# Usage: lpunpack_py.sh <super_image> <output_dir> [partition_name]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SUPER_IMAGE="$1"
OUTPUT_DIR="${2:-.}"
PARTITION="$3"

if [ -z "$SUPER_IMAGE" ]; then
    echo "Usage: $0 <super_image> <output_dir> [partition_name]"
    exit 1
fi

if [ -n "$PARTITION" ]; then
    python3 "${SCRIPT_DIR}/dumprx_unpacker.py" lpunpack -p "$PARTITION" "$SUPER_IMAGE" "$OUTPUT_DIR"
else
    python3 "${SCRIPT_DIR}/dumprx_unpacker.py" lpunpack "$SUPER_IMAGE" "$OUTPUT_DIR"
fi
