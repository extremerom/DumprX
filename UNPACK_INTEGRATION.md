# UNPACK Module Integration

This document describes the UNPACK logic integrated from MIO-KITCHEN-SOURCE repository.

## Overview

The UNPACK module (`utils/unpack/`) provides advanced firmware unpacking capabilities for various Android image formats and firmware packages.

## Integrated Components

### High Priority Tools (Fully Integrated)

1. **lpunpack.py** - Super Image unpacker
   - Unpacks Android dynamic partition super images
   - Supports metadata parsing and extraction
   - Usage: `from unpack import LpUnpackError`

2. **unpac.py** - SPRD PAC file unpacker
   - Extracts Spreadtrum PAC firmware files
   - Wrapper script: `utils/pacextractor/python/pacExtractor.py`
   - Usage: `from unpack import unpac, UnpacMode`

3. **cpio.py** - CPIO archive handler
   - Extracts and repacks CPIO archives (ramdisk)
   - Usage: `from unpack import cpio_extract, cpio_repack, CpioMagicFormat`

4. **sparse_img.py** - Sparse image handler
   - Handles Android sparse image format
   - Usage: `from unpack import SparseImage`

5. **ext4.py** - EXT4 image parser
   - Parses and extracts EXT4 filesystem images
   - Usage: `from unpack import Ext4Volume, Ext4Inode`

6. **imgextractor.py** - Image extraction utilities
   - Generic image extraction helper
   - Usage: `from unpack import Extractor`

### Medium Priority Tools (Integrated)

7. **payload_extract.py** - OTA Payload extractor
   - Extracts Android OTA update payloads
   - Usage: `from unpack import extract_partitions_from_payload, init_payload_info`

8. **aml_image.py** - Amlogic V2 image unpacker
   - Unpacks Amlogic V2 firmware images

9. **ozipdecrypt.py** - OZIP decryptor
   - Decrypts Oppo/OnePlus OZIP firmware files
   - Usage: `from unpack import decrypt_ozip`

10. **opscrypto.py** - OPS firmware extractor
    - Extracts OnePlus/Oppo OPS firmware files
    - Usage: `from unpack import decrypt_ops`

### Supporting Modules

- **utils.py** - Utility functions including Sdat2img class
- **rangelib.py** - Range handling for sparse images
- **posix.py** - POSIX compatibility helpers
- **blockimgdiff.py** - Block image differential update support
- **update_metadata_pb2.py** - Protobuf definitions for OTA metadata
- **dz.py, kdz.py, gpt.py** - LG KDZ firmware support

## Updated Binaries

The following binaries have been updated from MIO-KITCHEN-SOURCE:

- **extract.erofs** - EROFS filesystem extractor (improved version)
- **mkfs.erofs** - EROFS filesystem creator
- **brotli** - Brotli compression/decompression
- **img2simg** - Raw to sparse image converter
- **magiskboot** - Boot image unpacker/repacker

## Dependencies

The unpack module requires the following Python packages (see `requirements.txt`):

- pycryptodome>=3.19.1 - Encryption/decryption
- protobuf>=5 - Protocol buffers for OTA metadata
- toml - TOML configuration file support
- zstandard - Zstandard compression
- cryptography - Advanced cryptographic operations
- lxml - XML parsing

## Usage Examples

### Extract SPRD PAC file
```bash
python3 utils/pacextractor/python/pacExtractor.py firmware.pac output_dir/
```

### Extract CPIO archive (Python)
```python
from unpack import cpio_extract
cpio_extract('ramdisk.cpio', 'output_dir/', 'output_info.txt')
```

### Unpack Super Image (Python)
```python
from unpack import lpunpack
# Use lpunpack module programmatically
```

### Convert DAT to IMG using Sdat2img class
```python
from unpack import Sdat2img
converter = Sdat2img('system.transfer.list', 'system.new.dat', 'system.img')
```

## Integration Points in dumper.sh

The unpack module is integrated into dumper.sh through:

1. PAC extraction via `utils/pacextractor/python/pacExtractor.py`
2. SDAT2IMG operations using the existing `utils/sdat2img.py`
3. Binary tools in `utils/bin/` for EROFS, brotli, sparse images

## Notes

- The current KDZ tools (`utils/kdztools/`) are retained as they are more complete than the MIO-KITCHEN versions
- The current `splituapp.py` is retained as it's more feature-complete
- The current `sdat2img.py` wrapper is retained for shell script compatibility
- Binary lpunpack tool is retained alongside the Python module for flexibility

## Credits

The UNPACK module is based on work from:
- MIO-KITCHEN-SOURCE project (https://github.com/ColdWindScholar/MIO-KITCHEN-SOURCE)
- Original Android Open Source Project (AOSP)
- Various firmware extraction tool authors

## License

The integrated modules maintain their original licenses:
- GNU AGPL v3.0 for MIO-KITCHEN-SOURCE components
- Apache 2.0 for AOSP-derived components
