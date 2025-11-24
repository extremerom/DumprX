#!/bin/bash

# Shared utility functions for payload processing
# Common functions used across multiple scripts

# Function to read 64-bit unsigned integer from file (little-endian)
read_uint64() {
    local file=$1
    local offset=$2
    dd if="$file" bs=1 skip=$offset count=8 2>/dev/null | od -An -t u8 | tr -d ' '
}

# Function to read 32-bit unsigned integer from file (little-endian)
read_uint32() {
    local file=$1
    local offset=$2
    dd if="$file" bs=1 skip=$offset count=4 2>/dev/null | od -An -t u4 | tr -d ' '
}

# Function to get file size in bytes (cross-platform)
get_file_size() {
    local file=$1
    if [[ ! -f "$file" ]]; then
        echo "0"
        return 1
    fi
    # Try BSD stat first, then GNU stat
    stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0"
}

# Function to format bytes to human readable
format_bytes() {
    local bytes=$1
    if [[ $bytes -lt 1024 ]]; then
        echo "${bytes}B"
    elif [[ $bytes -lt 1048576 ]]; then
        echo "$((bytes / 1024))KB"
    elif [[ $bytes -lt 1073741824 ]]; then
        echo "$((bytes / 1048576))MB"
    else
        echo "$((bytes / 1073741824))GB"
    fi
}

# Export functions
export -f read_uint64
export -f read_uint32
export -f get_file_size
export -f format_bytes
