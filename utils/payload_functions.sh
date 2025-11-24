#!/bin/bash

# Payload.bin validation and processing functions
# Supports header versions v2, v3, v4
# Can be sourced by other scripts

# Function to validate payload.bin header
validate_payload_header() {
    local payload_file=$1
    local verbose=${2:-false}
    
    if [[ ! -f "$payload_file" ]]; then
        [[ "$verbose" == "true" ]] && echo "ERROR: File not found: $payload_file"
        return 1
    fi
    
    # Check magic bytes "CrAU"
    local magic=$(dd if="$payload_file" bs=1 count=4 2>/dev/null)
    if [[ "$magic" != "CrAU" ]]; then
        [[ "$verbose" == "true" ]] && echo "ERROR: Invalid payload - magic bytes do not match 'CrAU'"
        return 1
    fi
    
    # Read file format version (offset 4, 8 bytes)
    local version=$(dd if="$payload_file" bs=1 skip=4 count=8 2>/dev/null | od -An -t u8 | tr -d ' ')
    
    # Check if version is supported (v2, v3, v4)
    if [[ $version -lt 2 || $version -gt 4 ]]; then
        [[ "$verbose" == "true" ]] && echo "ERROR: Unsupported header version: v$version (supported: v2, v3, v4)"
        return 1
    fi
    
    [[ "$verbose" == "true" ]] && echo "OK: Valid payload.bin with header v$version"
    echo "$version"
    return 0
}

# Function to get payload header version
get_payload_version() {
    local payload_file=$1
    
    if [[ ! -f "$payload_file" ]]; then
        echo "0"
        return 1
    fi
    
    # Check magic bytes
    local magic=$(dd if="$payload_file" bs=1 count=4 2>/dev/null)
    if [[ "$magic" != "CrAU" ]]; then
        echo "0"
        return 1
    fi
    
    # Read version
    local version=$(dd if="$payload_file" bs=1 skip=4 count=8 2>/dev/null | od -An -t u8 | tr -d ' ')
    echo "$version"
    return 0
}

# Function to get human-readable version info
get_payload_version_info() {
    local version=$1
    
    case $version in
        2)
            echo "Android Oreo/Pie (A/B OTA with integrity signature)"
            ;;
        3)
            echo "Android Q/R (Dynamic partitions support)"
            ;;
        4)
            echo "Android S+ (Virtual A/B, snapshot-based updates)"
            ;;
        *)
            echo "Unknown version"
            ;;
    esac
}

# Function to extract payload with enhanced error handling
extract_payload_safe() {
    local payload_file=$1
    local output_dir=$2
    local extractor_tool=$3
    local concurrency=${4:-4}
    
    # Validate payload first
    local version=$(validate_payload_header "$payload_file" false)
    local ret=$?
    
    if [[ $ret -ne 0 ]]; then
        echo "ERROR: Payload validation failed"
        return 1
    fi
    
    echo "Detected payload.bin with header v$version"
    echo "$(get_payload_version_info "$version")"
    
    # Create output directory
    mkdir -p "$output_dir" 2>/dev/null
    
    # Extract using payload-dumper-go
    if [[ -x "$extractor_tool" ]]; then
        echo "Extracting payload with $concurrency concurrent workers..."
        "$extractor_tool" -c "$concurrency" -o "$output_dir" "$payload_file"
        local extract_ret=$?
        
        if [[ $extract_ret -eq 0 ]]; then
            echo "Payload extraction completed successfully"
            return 0
        else
            echo "ERROR: Payload extraction failed with exit code $extract_ret"
            return $extract_ret
        fi
    else
        echo "ERROR: Extractor tool not found or not executable: $extractor_tool"
        return 1
    fi
}

# Function to list partitions in payload
list_payload_partitions() {
    local payload_file=$1
    local extractor_tool=$2
    
    if [[ ! -x "$extractor_tool" ]]; then
        echo "ERROR: Extractor tool not available"
        return 1
    fi
    
    # Validate first
    validate_payload_header "$payload_file" false >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        echo "ERROR: Invalid payload file"
        return 1
    fi
    
    # List partitions
    "$extractor_tool" -l "$payload_file"
    return $?
}

# Function to extract specific partitions
extract_payload_partitions() {
    local payload_file=$1
    local output_dir=$2
    local extractor_tool=$3
    local partitions=$4  # comma-separated list
    
    # Validate payload
    validate_payload_header "$payload_file" true
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    mkdir -p "$output_dir" 2>/dev/null
    
    echo "Extracting specific partitions: $partitions"
    "$extractor_tool" -p "$partitions" -o "$output_dir" "$payload_file"
    return $?
}

# Function to verify payload checksums (if supported)
verify_payload_checksums() {
    local payload_file=$1
    
    # This is a placeholder for checksum verification
    # The actual implementation would need to parse the protobuf manifest
    # and verify SHA256 checksums of extracted partitions
    
    echo "INFO: Checksum verification not yet implemented"
    echo "INFO: payload-dumper-go performs automatic verification during extraction"
    return 0
}

# Export functions for use in other scripts
export -f validate_payload_header
export -f get_payload_version
export -f get_payload_version_info
export -f extract_payload_safe
export -f list_payload_partitions
export -f extract_payload_partitions
export -f verify_payload_checksums
