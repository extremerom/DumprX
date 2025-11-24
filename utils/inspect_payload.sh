#!/bin/bash

# Script to inspect Android OTA payload.bin files
# Supports header versions v2, v3, v4
# Shows metadata information without full extraction

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

function print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   Android OTA Payload Inspector${NC}"
    echo -e "${BLUE}========================================${NC}"
}

function print_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

function print_success() {
    echo -e "${GREEN}[OK] $1${NC}"
}

function print_info() {
    echo -e "${YELLOW}[INFO] $1${NC}"
}

function usage() {
    echo "Usage: $0 <payload.bin>"
    echo ""
    echo "This script inspects Android OTA payload.bin files and displays:"
    echo "  - Header version (v2, v3, v4)"
    echo "  - Manifest size"
    echo "  - Metadata signature size"
    echo "  - List of partitions"
    echo "  - Partition sizes and operations"
    exit 1
}

function read_uint64() {
    local file=$1
    local offset=$2
    # Read 8 bytes in little-endian format
    local bytes=$(dd if="$file" bs=1 skip=$offset count=8 2>/dev/null | od -An -t u8 | tr -d ' ')
    echo "$bytes"
}

function read_uint32() {
    local file=$1
    local offset=$2
    # Read 4 bytes in little-endian format
    local bytes=$(dd if="$file" bs=1 skip=$offset count=4 2>/dev/null | od -An -t u4 | tr -d ' ')
    echo "$bytes"
}

function inspect_payload() {
    local payload_file=$1
    
    if [[ ! -f "$payload_file" ]]; then
        print_error "File not found: $payload_file"
        exit 1
    fi
    
    print_header
    echo ""
    echo -e "File: ${GREEN}$payload_file${NC}"
    echo -e "Size: $(du -h "$payload_file" | cut -f1)"
    echo ""
    
    # Check magic bytes "CrAU"
    local magic=$(dd if="$payload_file" bs=1 count=4 2>/dev/null)
    if [[ "$magic" != "CrAU" ]]; then
        print_error "Invalid payload file. Magic bytes do not match 'CrAU'"
        print_info "Found: $(echo -n "$magic" | od -An -tx1 | tr -d ' ')"
        exit 1
    fi
    print_success "Valid Android OTA Payload (Magic: CrAU)"
    
    # Read file format version (offset 4, 8 bytes)
    local version=$(read_uint64 "$payload_file" 4)
    echo -e "${YELLOW}Header Version:${NC} v$version"
    
    case $version in
        2)
            print_info "Android Oreo/Pie (A/B updates with integrity signature)"
            ;;
        3)
            print_info "Android Q/R (Dynamic partitions support)"
            ;;
        4)
            print_info "Android S+ (Virtual A/B, snapshot-based updates)"
            ;;
        *)
            print_error "Unknown or unsupported header version: v$version"
            ;;
    esac
    
    # Read manifest size (offset 12, 8 bytes)
    local manifest_size=$(read_uint64 "$payload_file" 12)
    echo -e "${YELLOW}Manifest Size:${NC} $manifest_size bytes"
    
    # Read metadata signature size (offset 20, 4 bytes) - only in v2+
    if [[ $version -ge 2 ]]; then
        local metadata_sig_size=$(read_uint32 "$payload_file" 20)
        echo -e "${YELLOW}Metadata Signature Size:${NC} $metadata_sig_size bytes"
        
        # Calculate data offset
        local data_offset=$((24 + manifest_size + metadata_sig_size))
        echo -e "${YELLOW}Data Blob Offset:${NC} $data_offset bytes"
    fi
    
    echo ""
    print_success "Payload header information extracted successfully"
    echo ""
    
    # Try to list partitions if payload-dumper-go is available
    local payload_dumper="${PAYLOAD_DUMPER:-./utils/bin/payload-dumper-go}"
    if [[ -x "$payload_dumper" ]]; then
        echo -e "${BLUE}Partition List:${NC}"
        echo "----------------------------------------"
        "$payload_dumper" -l "$payload_file" 2>/dev/null || {
            print_error "Failed to list partitions with payload-dumper-go"
        }
        echo ""
    else
        print_info "payload-dumper-go not found. Skipping partition list."
        print_info "Set PAYLOAD_DUMPER environment variable to use custom path."
    fi
}

# Main
if [[ $# -eq 0 ]]; then
    usage
fi

inspect_payload "$1"
