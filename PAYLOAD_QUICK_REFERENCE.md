# Quick Reference: Payload.bin Tools

## Quick Commands

### Inspect a payload.bin file
```bash
./utils/inspect_payload.sh firmware/payload.bin
```

### Extract payload.bin with main script
```bash
./dumper.sh firmware.zip
# or
./dumper.sh firmware/payload.bin
```

### Extract metadata only
```bash
./utils/extract_payload_metadata.sh firmware/payload.bin metadata.pb
```

### Manual extraction with validation
```bash
source utils/payload_functions.sh
validate_payload_header firmware/payload.bin true
list_payload_partitions firmware/payload.bin utils/bin/payload-dumper-go
extract_payload_safe firmware/payload.bin ./output utils/bin/payload-dumper-go 8
```

### Advanced extraction with retry
```bash
source utils/payload_advanced.sh
extract_with_retry firmware/payload.bin ./output utils/bin/payload-dumper-go 8 2
create_extraction_report ./output firmware/payload.bin
```

## Header Version Quick Reference

| Version | Android       | Features                           |
|---------|---------------|------------------------------------|
| v2      | 8.x - 9.x     | A/B OTA, basic partitions          |
| v3      | 10 - 11       | Dynamic partitions, compression    |
| v4      | 12+           | Virtual A/B, snapshots             |

## Common Issues

### "Invalid payload - magic bytes do not match"
- File is corrupted or not a valid payload.bin
- Re-download the firmware

### "Unsupported header version"
- Payload uses a version not in v2-v4
- Update payload-dumper-go tool

### "Extraction failed"
- Check disk space (need 2.5x payload size)
- Verify payload file integrity
- Try with fewer workers

### "Insufficient disk space"
- Free up space or use different output directory
- Typical requirement: 2.5x the payload.bin size

## File Locations

- **Main script**: `dumper.sh`
- **Inspection tool**: `utils/inspect_payload.sh`
- **Basic functions**: `utils/payload_functions.sh`
- **Advanced functions**: `utils/payload_advanced.sh`
- **Metadata extractor**: `utils/extract_payload_metadata.sh`
- **Extraction tool**: `utils/bin/payload-dumper-go`
- **Full documentation**: `PAYLOAD_SUPPORT.md`

## Environment Variables

Set these to customize behavior:

```bash
# Custom payload-dumper-go path
export PAYLOAD_DUMPER=/path/to/custom/payload-dumper-go

# Number of extraction workers (default: nproc)
export PAYLOAD_WORKERS=4
```

## Tips for Best Performance

1. **Use SSD storage** for extraction (2-3x faster)
2. **Maximize workers** up to CPU core count
3. **Extract only needed partitions** with `-p` flag
4. **Ensure adequate space** before starting
5. **Use retry mode** for unreliable storage

## Scripting Examples

### Batch process multiple payloads
```bash
#!/bin/bash
for payload in firmware/*.bin; do
    echo "Processing $payload..."
    ./utils/inspect_payload.sh "$payload"
    ./dumper.sh "$payload"
done
```

### Extract specific partitions only
```bash
#!/bin/bash
source utils/payload_functions.sh
PARTITIONS="system,vendor,boot"
extract_payload_partitions payload.bin ./output utils/bin/payload-dumper-go "$PARTITIONS"
```

### Validate before extraction
```bash
#!/bin/bash
source utils/payload_functions.sh
source utils/payload_advanced.sh

if validate_payload_header payload.bin false >/dev/null; then
    if check_disk_space ./output payload.bin; then
        extract_with_retry payload.bin ./output utils/bin/payload-dumper-go 8 2
    fi
fi
```
