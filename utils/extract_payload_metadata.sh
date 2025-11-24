#!/bin/bash

# Script to extract and display metadata from payload.bin
# This extracts the protobuf manifest without extracting the full payload

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

function usage() {
    echo "Usage: $0 <payload.bin> [output_file]"
    echo ""
    echo "Extracts the protobuf manifest (metadata) from an Android OTA payload.bin"
    echo ""
    echo "Arguments:"
    echo "  payload.bin    - Input payload file"
    echo "  output_file    - (Optional) Output file for manifest (default: manifest.pb)"
    echo ""
    echo "Example:"
    echo "  $0 payload.bin metadata.pb"
    exit 1
}

function read_uint64() {
    local file=$1
    local offset=$2
    dd if="$file" bs=1 skip=$offset count=8 2>/dev/null | od -An -t u8 | tr -d ' '
}

function read_uint32() {
    local file=$1
    local offset=$2
    dd if="$file" bs=1 skip=$offset count=4 2>/dev/null | od -An -t u4 | tr -d ' '
}

function extract_manifest() {
    local payload_file=$1
    local output_file=${2:-manifest.pb}
    
    if [[ ! -f "$payload_file" ]]; then
        echo -e "${RED}[ERROR] File not found: $payload_file${NC}"
        exit 1
    fi
    
    # Check magic
    local magic=$(dd if="$payload_file" bs=1 count=4 2>/dev/null)
    if [[ "$magic" != "CrAU" ]]; then
        echo -e "${RED}[ERROR] Invalid payload file${NC}"
        exit 1
    fi
    
    # Read version
    local version=$(read_uint64 "$payload_file" 4)
    echo -e "${GREEN}Payload version: v$version${NC}"
    
    # Read manifest size
    local manifest_size=$(read_uint64 "$payload_file" 12)
    echo -e "${YELLOW}Manifest size: $manifest_size bytes${NC}"
    
    # Calculate manifest offset
    local manifest_offset=24
    if [[ $version -ge 2 ]]; then
        # Version 2+ has metadata signature size field
        manifest_offset=24
    fi
    
    # Extract manifest
    echo -e "${BLUE}Extracting manifest to: $output_file${NC}"
    dd if="$payload_file" bs=1 skip=$manifest_offset count=$manifest_size of="$output_file" 2>/dev/null
    
    if [[ -f "$output_file" ]]; then
        echo -e "${GREEN}[OK] Manifest extracted successfully${NC}"
        echo -e "Size: $(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file") bytes"
        
        # Try to display some info using protoc if available
        if command -v protoc >/dev/null 2>&1; then
            echo -e "\n${YELLOW}Note: You can decode this manifest using protoc with update_metadata.proto${NC}"
            echo "Example: protoc --decode=DeltaArchiveManifest update_metadata.proto < $output_file"
        fi
    else
        echo -e "${RED}[ERROR] Failed to extract manifest${NC}"
        exit 1
    fi
}

# Main
if [[ $# -eq 0 ]]; then
    usage
fi

extract_manifest "$1" "$2"
