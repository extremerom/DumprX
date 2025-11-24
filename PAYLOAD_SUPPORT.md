# Payload.bin Processing Utilities

## Overview

DumprX now includes enhanced support for Android OTA payload.bin files with automatic detection and validation of header versions v2, v3, and v4.

## Supported Header Versions

### Version 2 (v2)
- **Android Version**: Oreo (8.x) / Pie (9.x)
- **Features**: 
  - A/B OTA updates
  - Integrity signature support
  - Basic partition updates
- **Use Case**: Older devices with A/B partitions

### Version 3 (v3)
- **Android Version**: Q (10) / R (11)
- **Features**:
  - Dynamic partitions support
  - Enhanced compression methods
  - Extended manifest fields
- **Use Case**: Devices with dynamic partition support

### Version 4 (v4)
- **Android Version**: S (12) / T (13) and newer
- **Features**:
  - Virtual A/B updates
  - Snapshot-based update flow
  - Advanced compression and differential updates
- **Use Case**: Modern devices with Virtual A/B support

## New Utilities

### 1. inspect_payload.sh

Inspect payload.bin files without extracting them.

**Usage:**
```bash
./utils/inspect_payload.sh path/to/payload.bin
```

**Output:**
- Magic bytes validation
- Header version (v2, v3, v4)
- Manifest size
- Metadata signature size
- Data blob offset
- List of partitions (if payload-dumper-go is available)

**Example:**
```bash
./utils/inspect_payload.sh /path/to/firmware/payload.bin
```

Output:
```
========================================
   Android OTA Payload Inspector
========================================

File: /path/to/firmware/payload.bin
Size: 2.5G

[OK] Valid Android OTA Payload (Magic: CrAU)
Header Version: v4
[INFO] Android S+ (Virtual A/B, snapshot-based updates)
Manifest Size: 45678 bytes
Metadata Signature Size: 256 bytes
Data Blob Offset: 45958 bytes

[OK] Payload header information extracted successfully

Partition List:
----------------------------------------
boot
dtbo
product
system
system_ext
vendor
vendor_boot
...
```

### 2. payload_functions.sh

Library of functions for payload processing that can be sourced by other scripts.

**Available Functions:**

#### validate_payload_header
Validates payload.bin header and returns version number.
```bash
source utils/payload_functions.sh
version=$(validate_payload_header payload.bin true)
echo "Version: v$version"
```

#### get_payload_version
Gets the header version number without validation messages.
```bash
version=$(get_payload_version payload.bin)
```

#### get_payload_version_info
Returns human-readable information about a version.
```bash
info=$(get_payload_version_info 4)
echo "$info"  # Output: Android S+ (Virtual A/B, snapshot-based updates)
```

#### extract_payload_safe
Extracts payload with validation and error handling.
```bash
extract_payload_safe payload.bin output_dir /path/to/payload-dumper-go 8
```

#### list_payload_partitions
Lists all partitions in payload.bin.
```bash
list_payload_partitions payload.bin /path/to/payload-dumper-go
```

#### extract_payload_partitions
Extracts specific partitions only.
```bash
extract_payload_partitions payload.bin output_dir /path/to/payload-dumper-go "system,vendor,boot"
```

#### verify_payload_checksums
Placeholder for checksum verification (performed automatically by payload-dumper-go).
```bash
verify_payload_checksums payload.bin
```

## Advanced Payload Functions (payload_advanced.sh)

For power users, additional advanced functions are available in `utils/payload_advanced.sh`:

### verify_partition_checksum
Verify SHA256 checksum of an extracted partition.
```bash
source utils/payload_advanced.sh
verify_partition_checksum system.img <expected_sha256>
```

### estimate_extraction_time
Estimate how long extraction will take based on file size and workers.
```bash
estimate_extraction_time payload.bin 8
# Output: 5m
```

### check_disk_space
Check if sufficient disk space is available before extraction.
```bash
check_disk_space /output/directory payload.bin
# Required space: ~7GB
# Available space: 50GB
# ✓ Sufficient disk space available
```

### extract_with_progress
Extract with detailed progress information and timing.
```bash
extract_with_progress payload.bin output_dir /path/to/payload-dumper-go 8
```

### extract_with_retry
Extract with automatic retry on failure (reduces workers on retry).
```bash
extract_with_retry payload.bin output_dir /path/to/payload-dumper-go 8 2
# Attempts extraction up to 2 times with adjusted settings
```

### create_extraction_report
Generate a detailed report of extracted partitions with checksums.
```bash
create_extraction_report output_dir payload.bin
# Creates: output_dir/extraction_report.txt
```

## Integration with dumper.sh

The main dumper.sh script now automatically:

1. **Detects** payload.bin files in firmware packages
2. **Validates** the header version (v2, v3, v4)
3. **Displays** version information and compatibility
4. **Lists** available partitions before extraction
5. **Extracts** with enhanced error handling and retry capability
6. **Generates** extraction reports with checksums
7. **Falls back** to basic extraction if validation fails

### Example Flow

When dumper.sh encounters a payload.bin file:

```
AB OTA Payload Detected
Validating payload.bin header...
[OK] Valid payload.bin with header v4
Payload Header Version: v4
Info: Android S+ (Virtual A/B, snapshot-based updates)

Listing partitions in payload.bin...
boot
dtbo
product
system
system_ext
vendor
vendor_boot

Using enhanced extraction with retry capability...
=========================================
Payload Extraction Summary
=========================================
File: payload.bin
Size: 2.5G
Output: /path/to/output
Workers: 8
Estimated time: 5m
=========================================

Required space: ~7GB
Available space: 50GB
✓ Sufficient disk space available

Starting extraction...

=========================================
✓ Extraction completed successfully
Time elapsed: 287s
=========================================

Extracted partitions:
  boot.img (64M)
  dtbo.img (8.0M)
  product.img (1.2G)
  system.img (2.8G)
  system_ext.img (456M)
  vendor.img (789M)
  vendor_boot.img (32M)

Extraction report saved to: /path/to/output/extraction_report.txt
```

## Technical Details

### Payload.bin Structure

```
+------------------+
| Magic (CrAU)     | 4 bytes
+------------------+
| Version          | 8 bytes (uint64)
+------------------+
| Manifest Size    | 8 bytes (uint64)
+------------------+
| Metadata Sig Sz  | 4 bytes (uint32) - v2+
+------------------+
| Manifest         | Variable (protobuf)
+------------------+
| Metadata Sig     | Variable
+------------------+
| Data Blobs       | Variable
+------------------+
| Payload Sig      | Variable
+------------------+
```

### Header Reading

The scripts use `dd` and `od` to read binary data:
- **Magic bytes**: First 4 bytes should be "CrAU"
- **Version**: Bytes 4-11 as little-endian uint64
- **Manifest size**: Bytes 12-19 as little-endian uint64
- **Metadata sig size**: Bytes 20-23 as little-endian uint32 (v2+)

### Validation Process

1. Check magic bytes match "CrAU"
2. Read version number
3. Verify version is 2, 3, or 4
4. Read manifest and signature sizes
5. Validate file structure integrity

## Troubleshooting

### "Invalid payload - magic bytes do not match 'CrAU'"

The file is not a valid Android OTA payload.bin or is corrupted.

**Solution**: Verify the firmware source and re-download if necessary.

### "Unsupported header version: vX"

The payload uses a header version other than v2, v3, or v4.

**Solution**: Check if your payload-dumper-go supports this version, or try updating the tool.

### "Payload extraction failed"

The extraction process encountered an error.

**Solution**: 
- Check available disk space
- Verify payload.bin is not corrupted
- Try with fewer concurrent workers
- Check the log files in the tmp directory

### Payload-dumper-go not found

The extraction tool is missing or not executable.

**Solution**: Run `./setup.sh` to install dependencies, or check that `utils/bin/payload-dumper-go` exists and is executable.

## Advanced Usage

### Extract Only Specific Partitions

If you only need certain partitions (e.g., system and vendor):

```bash
source utils/payload_functions.sh
extract_payload_partitions payload.bin ./output /path/to/payload-dumper-go "system,vendor"
```

### Custom Validation Script

```bash
#!/bin/bash
source utils/payload_functions.sh

PAYLOAD="payload.bin"

# Validate
if validate_payload_header "$PAYLOAD" false >/dev/null 2>&1; then
    VERSION=$(get_payload_version "$PAYLOAD")
    INFO=$(get_payload_version_info "$VERSION")
    
    echo "Valid payload detected:"
    echo "  Version: v$VERSION"
    echo "  Info: $INFO"
    
    # List partitions
    echo "Partitions:"
    list_payload_partitions "$PAYLOAD" ./utils/bin/payload-dumper-go
else
    echo "Invalid or unsupported payload"
    exit 1
fi
```

## Performance Tips

1. **Use multiple workers**: The `-c` flag for payload-dumper-go uses multiple CPU cores
   ```bash
   payload-dumper-go -c $(nproc --all) -o output payload.bin
   ```

2. **Extract only needed partitions**: Use `-p` flag to extract specific partitions
   ```bash
   payload-dumper-go -p system,vendor -o output payload.bin
   ```

3. **Check available space**: Ensure you have at least 2x the payload.bin size in free space

4. **Use SSD storage**: Extraction is I/O intensive and benefits from faster storage

## References

- [Android OTA Documentation](https://source.android.com/docs/core/ota)
- [Update Engine Protocol](https://android.googlesource.com/platform/system/update_engine/)
- [Payload Dumper Go](https://github.com/ssut/payload-dumper-go)
- [Update Metadata Proto](https://github.com/tobyxdd/android-ota-payload-extractor/blob/master/update_metadata.proto)
