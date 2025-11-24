#!/bin/bash

# Advanced payload processing functions
# Includes checksum validation, progress tracking, and recovery

# Function to verify extracted partition checksums
verify_partition_checksum() {
    local partition_file=$1
    local expected_sha256=$2
    
    if [[ ! -f "$partition_file" ]]; then
        echo "ERROR: Partition file not found: $partition_file"
        return 1
    fi
    
    if [[ -z "$expected_sha256" ]]; then
        echo "WARNING: No expected checksum provided, skipping validation"
        return 0
    fi
    
    echo "Calculating SHA256 checksum for $(basename "$partition_file")..."
    local actual_sha256=$(sha256sum "$partition_file" | awk '{print $1}')
    
    if [[ "$actual_sha256" == "$expected_sha256" ]]; then
        echo "✓ Checksum verified: $(basename "$partition_file")"
        return 0
    else
        echo "✗ Checksum mismatch for $(basename "$partition_file")"
        echo "  Expected: $expected_sha256"
        echo "  Actual:   $actual_sha256"
        return 1
    fi
}

# Function to estimate extraction time based on payload size
estimate_extraction_time() {
    local payload_file=$1
    local num_workers=${2:-4}
    
    if [[ ! -f "$payload_file" ]]; then
        echo "Unknown"
        return 1
    fi
    
    # Get file size in MB
    local size_bytes=$(stat -f%z "$payload_file" 2>/dev/null || stat -c%s "$payload_file")
    local size_mb=$((size_bytes / 1024 / 1024))
    
    # Rough estimate: ~50MB/s per worker on average hardware
    local throughput_mb=$((50 * num_workers))
    local estimated_seconds=$((size_mb / throughput_mb))
    
    if [[ $estimated_seconds -lt 60 ]]; then
        echo "${estimated_seconds}s"
    elif [[ $estimated_seconds -lt 3600 ]]; then
        local minutes=$((estimated_seconds / 60))
        echo "${minutes}m"
    else
        local hours=$((estimated_seconds / 3600))
        local minutes=$(((estimated_seconds % 3600) / 60))
        echo "${hours}h ${minutes}m"
    fi
}

# Function to check available disk space before extraction
check_disk_space() {
    local output_dir=$1
    local payload_file=$2
    local required_multiplier=${3:-2.5}
    
    # Get payload size
    local payload_size=$(stat -f%z "$payload_file" 2>/dev/null || stat -c%s "$payload_file")
    local required_space=$((payload_size * required_multiplier / 1))
    
    # Get available space in output directory
    local available_space=$(df "$output_dir" | tail -1 | awk '{print $4}')
    # Convert to bytes (df usually returns in KB)
    available_space=$((available_space * 1024))
    
    local required_gb=$((required_space / 1024 / 1024 / 1024))
    local available_gb=$((available_space / 1024 / 1024 / 1024))
    
    echo "Required space: ~${required_gb}GB"
    echo "Available space: ${available_gb}GB"
    
    if [[ $available_space -lt $required_space ]]; then
        echo "WARNING: Insufficient disk space"
        echo "  You may need to free up space or use a different output directory"
        return 1
    else
        echo "✓ Sufficient disk space available"
        return 0
    fi
}

# Function to extract with progress monitoring
extract_with_progress() {
    local payload_file=$1
    local output_dir=$2
    local extractor=$3
    local workers=${4:-4}
    
    echo "========================================="
    echo "Payload Extraction Summary"
    echo "========================================="
    echo "File: $(basename "$payload_file")"
    echo "Size: $(du -h "$payload_file" | cut -f1)"
    echo "Output: $output_dir"
    echo "Workers: $workers"
    echo "Estimated time: $(estimate_extraction_time "$payload_file" "$workers")"
    echo "========================================="
    echo ""
    
    # Check disk space
    check_disk_space "$output_dir" "$payload_file" || {
        echo "Continuing anyway..."
    }
    
    echo ""
    echo "Starting extraction..."
    local start_time=$(date +%s)
    
    # Run extraction
    "$extractor" -c "$workers" -o "$output_dir" "$payload_file"
    local exit_code=$?
    
    local end_time=$(date +%s)
    local elapsed=$((end_time - start_time))
    
    if [[ $exit_code -eq 0 ]]; then
        echo ""
        echo "========================================="
        echo "✓ Extraction completed successfully"
        echo "Time elapsed: ${elapsed}s"
        echo "========================================="
        
        # List extracted partitions
        echo ""
        echo "Extracted partitions:"
        ls -lh "$output_dir"/*.img 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
    else
        echo ""
        echo "========================================="
        echo "✗ Extraction failed (exit code: $exit_code)"
        echo "Time elapsed: ${elapsed}s"
        echo "========================================="
    fi
    
    return $exit_code
}

# Function to handle extraction with automatic retry
extract_with_retry() {
    local payload_file=$1
    local output_dir=$2
    local extractor=$3
    local workers=${4:-4}
    local max_retries=${5:-2}
    
    local attempt=1
    local exit_code=1
    
    while [[ $attempt -le $max_retries && $exit_code -ne 0 ]]; do
        if [[ $attempt -gt 1 ]]; then
            echo ""
            echo "Retry attempt $attempt of $max_retries..."
            # Reduce workers on retry to avoid potential resource issues
            workers=$((workers / 2))
            [[ $workers -lt 1 ]] && workers=1
            echo "Using $workers workers for retry"
        fi
        
        extract_with_progress "$payload_file" "$output_dir" "$extractor" "$workers"
        exit_code=$?
        
        attempt=$((attempt + 1))
    done
    
    if [[ $exit_code -ne 0 ]]; then
        echo ""
        echo "ERROR: Extraction failed after $max_retries attempts"
        echo "Please check:"
        echo "  1. Payload file is not corrupted"
        echo "  2. Sufficient disk space is available"
        echo "  3. payload-dumper-go tool is up to date"
    fi
    
    return $exit_code
}

# Function to create extraction report
create_extraction_report() {
    local output_dir=$1
    local payload_file=$2
    local report_file="${output_dir}/extraction_report.txt"
    
    {
        echo "========================================"
        echo "Payload Extraction Report"
        echo "========================================"
        echo "Date: $(date)"
        echo "Payload: $(basename "$payload_file")"
        echo "Payload Size: $(du -h "$payload_file" | cut -f1)"
        echo ""
        
        # Get payload version info
        if [[ -f "${payload_file}" ]]; then
            local magic=$(dd if="$payload_file" bs=1 count=4 2>/dev/null)
            if [[ "$magic" == "CrAU" ]]; then
                local version=$(dd if="$payload_file" bs=1 skip=4 count=8 2>/dev/null | od -An -t u8 | tr -d ' ')
                echo "Payload Version: v$version"
                
                case $version in
                    2) echo "Android Version: Oreo/Pie (8/9)" ;;
                    3) echo "Android Version: Q/R (10/11)" ;;
                    4) echo "Android Version: S+ (12/13+)" ;;
                esac
            fi
        fi
        
        echo ""
        echo "Extracted Partitions:"
        echo "========================================"
        
        if ls "$output_dir"/*.img >/dev/null 2>&1; then
            for img in "$output_dir"/*.img; do
                if [[ -f "$img" ]]; then
                    local name=$(basename "$img")
                    local size=$(du -h "$img" | cut -f1)
                    local sha=$(sha256sum "$img" | awk '{print $1}')
                    echo "$name"
                    echo "  Size: $size"
                    echo "  SHA256: $sha"
                    echo ""
                fi
            done
        else
            echo "No partition images found"
        fi
        
        echo "========================================"
        echo "Report generated: $(date)"
    } > "$report_file"
    
    echo "Extraction report saved to: $report_file"
}

# Export functions
export -f verify_partition_checksum
export -f estimate_extraction_time
export -f check_disk_space
export -f extract_with_progress
export -f extract_with_retry
export -f create_extraction_report
