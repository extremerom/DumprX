# DumprX Unpacking Modules

This document describes the unpacking modules imported from [MIO-KITCHEN-SOURCE](https://github.com/ColdWindScholar/MIO-KITCHEN-SOURCE) and integrated into DumprX.

## Overview

DumprX now includes a comprehensive set of Python-based unpacking tools located in `utils/pylib/`. These modules provide support for extracting and processing various Android firmware formats.

## Installation

Before using the Python-based unpacking modules, install the required dependencies:

```bash
pip3 install -r utils/pylib/requirements.txt
```

Or install individually:
```bash
pip3 install pycryptodome protobuf requests zstandard toml
```

## Usage

### Command-Line Interface

The unified wrapper script `dumprx_unpacker.py` provides access to all unpacking modules:

```bash
python3 utils/dumprx_unpacker.py <command> [args...]
```

### Available Commands

#### Core Unpacking Tools

| Command | Description | Usage Example |
|---------|-------------|---------------|
| `payload` | Extract Android OTA payload.bin files | `python3 dumprx_unpacker.py payload -t bin -i payload.bin -o output/` |
| `lpunpack` | Unpack Android super.img (dynamic partitions) | `python3 dumprx_unpacker.py lpunpack super.img output/` |
| `imgextract` | Extract ext4 filesystem images | Library only (no CLI) |

#### Firmware Decryption Tools

| Command | Description | Usage Example |
|---------|-------------|---------------|
| `ozipdecrypt` | Decrypt Oppo/OnePlus OZIP files | `python3 dumprx_unpacker.py ozipdecrypt firmware.ozip` |
| `ofp_qc` | Decrypt OFP files (Qualcomm) | `python3 dumprx_unpacker.py ofp_qc firmware.ofp` |
| `ofp_mtk` | Decrypt OFP files (MediaTek) | `python3 dumprx_unpacker.py ofp_mtk firmware.ofp` |
| `opscrypto` | Decrypt OPS files | `python3 dumprx_unpacker.py opscrypto firmware.ops` |

#### Vendor-Specific Tools

| Command | Description | Usage Example |
|---------|-------------|---------------|
| `unpac` | Unpack SpreadTrum PAC files | `python3 dumprx_unpacker.py unpac firmware.pac output/` |
| `nb0extract` | Extract Nokia/Sharp/Infocus NB0 files | `python3 dumprx_unpacker.py nb0extract firmware.nb0` |
| `unkdz` | Unpack LG KDZ files | `python3 dumprx_unpacker.py unkdz firmware.kdz` |
| `undz` | Unpack LG DZ files | `python3 dumprx_unpacker.py undz firmware.dz` |
| `aml` | Unpack Amlogic V2 images | `python3 dumprx_unpacker.py aml image.img` |
| `allwinner` | Unpack Allwinner images | `python3 dumprx_unpacker.py allwinner image.img` |
| `qsb` | Process QSB images | `python3 dumprx_unpacker.py qsb image.qsb` |
| `ntpi` | Unpack NTPI images | `python3 dumprx_unpacker.py ntpi image.ntpi` |

#### Archive and Filesystem Tools

| Command | Description | Usage Example |
|---------|-------------|---------------|
| `cpio` | Unpack/repack CPIO archives | `python3 dumprx_unpacker.py cpio archive.cpio` |
| `romfs` | Unpack ROMFS filesystems | `python3 dumprx_unpacker.py romfs romfs.img` |
| `squashfs` | Handle SquashFS images | `python3 dumprx_unpacker.py squashfs image.squashfs` |

#### Image Processing Tools

| Command | Description | Usage Example |
|---------|-------------|---------------|
| `mkdtboimg` | Parse/Unpack/Repack DTBO images | `python3 dumprx_unpacker.py mkdtboimg dtbo.img` |
| `rsceutil` | Unpack/repack Rockchip resource images | `python3 dumprx_unpacker.py rsceutil resource.img` |

#### Patching Tools

| Command | Description | Usage Example |
|---------|-------------|---------------|
| `fspatch` | Patch fs_config before unpacking | `python3 dumprx_unpacker.py fspatch config/` |
| `contextpatch` | Patch file_contexts before repacking | `python3 dumprx_unpacker.py contextpatch contexts/` |

## Integration with dumper.sh

The main `dumper.sh` script automatically detects firmware types and uses the appropriate unpacking tools. The Python modules are integrated as follows:

### Payload Extraction

For AB OTA updates with payload.bin:
- Primary: `payload-dumper-go` (fast compiled binary)
- Alternative: Python `payload_extract.py` (more flexible, detailed output)

### Super Image Extraction

For dynamic partitions (super.img):
- Primary: `lpunpack` binary (fast)
- Alternative: Python `lpunpack.py` (more detailed information, JSON output support)

### Encrypted Firmware

DumprX now automatically detects and decrypts:
- OZIP files (Oppo/OnePlus)
- OFP files (Oppo, both Qualcomm and MediaTek variants)
- OPS files (OnePlus)

## Python Module Structure

```
utils/
├── pylib/
│   ├── __init__.py
│   ├── payload_extract.py      # OTA payload extractor
│   ├── lpunpack.py             # Super image unpacker
│   ├── imgextractor.py         # EXT4 image extractor
│   ├── sparse_img.py           # Sparse image handler
│   ├── blockimgdiff.py         # Block differential tool
│   ├── ext4.py                 # EXT4 filesystem library
│   ├── ozipdecrypt.py          # OZIP decryption
│   ├── ofp_qc_decrypt.py       # OFP Qualcomm decryption
│   ├── ofp_mtk_decrypt.py      # OFP MediaTek decryption
│   ├── opscrypto.py            # OPS decryption
│   ├── unpac.py                # PAC unpacker
│   ├── nb0_extractor.py        # NB0 extractor
│   ├── unkdz.py, undz.py       # KDZ/DZ tools
│   ├── cpio.py                 # CPIO handler
│   ├── romfs_parse.py          # ROMFS parser
│   ├── aml_image.py            # Amlogic tools
│   ├── allwinnerimage.py       # Allwinner tools
│   ├── mkdtboimg.py            # DTBO tools
│   ├── rsceutil.py             # Rockchip resource tools
│   ├── fspatch.py              # fs_config patcher
│   ├── contextpatch.py         # file_contexts patcher
│   ├── ntpiutils/              # NTPI unpacking utilities
│   └── ...
├── dumprx_unpacker.py          # Unified CLI wrapper
└── requirements.txt            # Python dependencies
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

1. The Python modules are designed to be backward compatible with existing scripts
2. Binary tools are preferred for performance where available
3. Python modules provide better error handling and logging
4. Some modules can output JSON for programmatic use
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

If a specific module doesn't have a main() function, it's designed to be used as a library only. Import it in your Python scripts:
```python
import sys
sys.path.insert(0, 'utils')
from pylib import imgextractor, ext4
```
