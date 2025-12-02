# DumprX Unpacking Modules

This document describes the unpacking modules integrated from [MIO-KITCHEN-SOURCE](https://github.com/ColdWindScholar/MIO-KITCHEN-SOURCE) into DumprX.

## Overview

DumprX includes comprehensive Python-based unpacking tools located in `utils/pylib/`. These modules are adapted to use the DumprX logging system and integrate directly with `dumper.sh`.

## Installation

Install the required Python dependencies:

```bash
pip3 install -r utils/pylib/requirements.txt
```

Or install individually:
```bash
pip3 install pycryptodome protobuf requests zstandard toml
```

## Module Integration

All Python modules in `utils/pylib/` are integrated with the DumprX logging system via `dumprx_logger.py`, which provides:
- Consistent log levels (DEBUG, INFO, SUCCESS, WARN, ERROR, FATAL)
- Colored output matching shell script logging
- Timestamp support
- Quiet and verbose mode support
- Environment variable configuration

### Direct Usage

The modules can be used directly without wrappers:

```bash
# Extract payload.bin
python3 utils/pylib/payload_extract.py -t bin -i payload.bin -o output/

# Unpack super.img
python3 utils/pylib/lpunpack.py super.img output/

# Decrypt OZIP
python3 utils/pylib/ozipdecrypt.py firmware.ozip

# Decrypt OFP (Qualcomm)
python3 utils/pylib/ofp_qc_decrypt.py firmware.ofp output/

# Decrypt OFP (MTK)
python3 utils/pylib/ofp_mtk_decrypt.py firmware.ofp output/

# Decrypt OPS
python3 utils/pylib/opscrypto.py decrypt firmware.ops
```

### Available Modules

#### Core Unpacking Tools

| Module | Description | Usage Example |
|--------|-------------|---------------|
| `payload_extract.py` | Extract Android OTA payload.bin files | `python3 pylib/payload_extract.py -t bin -i payload.bin -o output/` |
| `lpunpack.py` | Unpack Android super.img (dynamic partitions) | `python3 pylib/lpunpack.py super.img output/` |
| `imgextractor.py` | Extract ext4 filesystem images | Use as library in Python scripts |

#### Firmware Decryption Tools

| Module | Description | Usage Example |
|--------|-------------|---------------|
| `ozipdecrypt.py` | Decrypt Oppo/OnePlus OZIP files | `python3 pylib/ozipdecrypt.py firmware.ozip` |
| `ofp_qc_decrypt.py` | Decrypt OFP files (Qualcomm) | `python3 pylib/ofp_qc_decrypt.py firmware.ofp output/` |
| `ofp_mtk_decrypt.py` | Decrypt OFP files (MediaTek) | `python3 pylib/ofp_mtk_decrypt.py firmware.ofp output/` |
| `opscrypto.py` | Decrypt OPS files | `python3 pylib/opscrypto.py decrypt firmware.ops` |

#### Vendor-Specific Tools

| Module | Description | Usage Example |
|--------|-------------|---------------|
| `unpac.py` | Unpack SpreadTrum PAC files | `python3 pylib/unpac.py firmware.pac output/` |
| `nb0_extractor.py` | Extract Nokia/Sharp/Infocus NB0 files | `python3 pylib/nb0_extractor.py firmware.nb0` |
| `unkdz.py` | Unpack LG KDZ files | `python3 pylib/unkdz.py firmware.kdz` |
| `undz.py` | Unpack LG DZ files | `python3 pylib/undz.py firmware.dz` |
| `aml_image.py` | Unpack Amlogic V2 images | Use as library |
| `allwinnerimage.py` | Unpack Allwinner images | Use as library |
| `qsb_imger.py` | Process QSB images | Use as library |
| `ntpi_unpacker.py` | Unpack NTPI images | Use as library |

#### Archive and Filesystem Tools

| Module | Description | Usage Example |
|--------|-------------|---------------|
| `cpio.py` | Unpack/repack CPIO archives | Use as library |
| `romfs_parse.py` | Unpack ROMFS filesystems | Use as library |
| `squashfs.py` | Handle SquashFS images | Use as library |

#### Image Processing Tools

| Module | Description | Usage Example |
|--------|-------------|---------------|
| `mkdtboimg.py` | Parse/Unpack/Repack DTBO images | Use as library |
| `rsceutil.py` | Unpack/repack Rockchip resource images | Use as library |

#### Patching Tools

| Module | Description | Usage Example |
|--------|-------------|---------------|
| `fspatch.py` | Patch fs_config before unpacking | Use as library |
| `contextpatch.py` | Patch file_contexts before repacking | Use as library |

## Integration with dumper.sh

The main `dumper.sh` script automatically detects firmware types and uses the appropriate unpacking tools directly. The Python modules are called without wrappers for maximum efficiency.

### Automatic Decryption

DumprX automatically detects and decrypts:
- **OZIP files** (Oppo/OnePlus) - uses `pylib/ozipdecrypt.py`
- **OFP files** (Oppo, Qualcomm and MediaTek variants) - uses `pylib/ofp_qc_decrypt.py` and `pylib/ofp_mtk_decrypt.py`
- **OPS files** (OnePlus) - uses `pylib/opscrypto.py`

### DumprX Logger Integration

All Python modules use the unified `dumprx_logger.py` which provides:
- Consistent logging with shell scripts
- Color-coded output (INFO, SUCCESS, WARN, ERROR, etc.)
- Respects DUMPRX_VERBOSE_MODE and DUMPRX_QUIET_MODE environment variables
- Timestamps when enabled

Example log output:
```
[2025-12-02 19:30:15] [STEP] ▶ Extracting payload...
[2025-12-02 19:30:16] [INFO] ℹ️ Extracting partition: system
[2025-12-02 19:30:45] [SUCCESS] ✓ Extracted partition: system size: 2147483648
[2025-12-02 19:31:02] [SUCCESS] ✓ Payload extraction completed in 47.23 seconds
```

## Python Module Structure

```
utils/
├── pylib/
│   ├── __init__.py
│   ├── dumprx_logger.py         # Unified logging system
│   ├── payload_extract.py       # OTA payload extractor
│   ├── lpunpack.py              # Super image unpacker
│   ├── imgextractor.py          # EXT4 image extractor
│   ├── sparse_img.py            # Sparse image handler
│   ├── blockimgdiff.py          # Block differential tool
│   ├── ext4.py                  # EXT4 filesystem library
│   ├── ozipdecrypt.py           # OZIP decryption
│   ├── ofp_qc_decrypt.py        # OFP Qualcomm decryption
│   ├── ofp_mtk_decrypt.py       # OFP MediaTek decryption
│   ├── opscrypto.py             # OPS decryption
│   ├── unpac.py                 # PAC unpacker
│   ├── nb0_extractor.py         # NB0 extractor
│   ├── unkdz.py, undz.py        # KDZ/DZ tools
│   ├── cpio.py                  # CPIO handler
│   ├── romfs_parse.py           # ROMFS parser
│   ├── aml_image.py             # Amlogic tools
│   ├── allwinnerimage.py        # Allwinner tools
│   ├── mkdtboimg.py             # DTBO tools
│   ├── rsceutil.py              # Rockchip resource tools
│   ├── fspatch.py               # fs_config patcher
│   ├── contextpatch.py          # file_contexts patcher
│   ├── ntpiutils/               # NTPI unpacking utilities
│   └── ...
├── sdat2img.py                  # Standalone sdat2img (enhanced)
├── splituapp.py                 # UPDATE.APP extractor
└── ...
```

## Binary Tools

Additional binary tools from MIO-KITCHEN-SOURCE:

| Binary | Purpose |
|--------|---------|
| `brotli` | Decompress .br compressed files |
| `zstd` | Decompress zstd compressed files |
| `img2simg` | Convert raw images to sparse format |
| `e2fsdroid` | Create EXT4 images with Android metadata |
| `extract.erofs` | Extract EROFS filesystems |
| `extract.f2fs` | Extract F2FS filesystems |
| `lpmake` | Create super.img (dynamic partitions) |
| `make_ext4fs` | Create EXT4 filesystems (legacy) |
| `mke2fs` | Create EXT2/3/4 filesystems |
| `mkfs.erofs` | Create EROFS filesystems |
| `mkfs.f2fs` | Create F2FS filesystems |
| `sload.f2fs` | Load files into F2FS images |
| `cpio` | CPIO archive tool |

## Credits

These unpacking modules are adapted from:
- [MIO-KITCHEN-SOURCE](https://github.com/ColdWindScholar/MIO-KITCHEN-SOURCE) by ColdWindScholar and contributors
- Original tool authors as documented in the source files

## Notes

1. All modules use the DumprX logging system for consistent output
2. Modules can be imported as libraries or run directly
3. No wrapper scripts needed - direct integration with dumper.sh
4. Respects environment variables: DUMPRX_VERBOSE_MODE, DUMPRX_QUIET_MODE, DUMPRX_LOG_COLORS
5. All modules support the standard input/output patterns used in DumprX

## Troubleshooting

If you encounter import errors:
```bash
# Install all dependencies
pip3 install -r utils/pylib/requirements.txt

# Or install specific packages
pip3 install pycryptodome  # For encryption/decryption
pip3 install protobuf      # For payload handling
pip3 install zstandard     # For zstd compression
pip3 install toml          # For CPIO handling
```

If logging doesn't appear correctly:
```bash
# Enable colored output
export DUMPRX_LOG_COLORS=true

# Enable timestamps  
export DUMPRX_LOG_TIMESTAMP=true

# Enable verbose mode
export DUMPRX_VERBOSE_MODE=true
```

For library usage in Python scripts:
```python
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'utils'))

from pylib import imgextractor, ext4
from pylib import dumprx_logger as log

log.info("Starting extraction...")
```
