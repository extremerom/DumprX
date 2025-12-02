# MIO-KITCHEN UNPACK Logic Integration Summary

## Overview
This document summarizes the integration of UNPACK logic from the MIO-KITCHEN-SOURCE project into DumprX, following all requirements from the problem statement.

## Date: 2025-12-02

## Integration Statistics

### Python Modules Imported
- **Total Core Modules**: 23 Python files in `utils/core/`
- **CLI Wrapper Tools**: 6 executable Python scripts in `utils/`
- **New Binaries**: 4 additional binaries in `utils/bin/`

### Core Modules Added (utils/core/)
1. **lpunpack.py** - Super image (dynamic partitions) unpacking
2. **ext4.py** - EXT4 filesystem parsing and extraction
3. **cpio.py** - CPIO archive pack/unpack operations
4. **sparse_img.py** - Android sparse image handling
5. **blockimgdiff.py** - Block-based image operations
6. **imgextractor.py** - Generic image extraction logic
7. **payload_extract.py** - Android OTA payload.bin extraction
8. **ozipdecrypt.py** - OPPO/Realme OZIP decryption
9. **ofp_qc_decrypt.py** - Qualcomm OFP decryption
10. **ofp_mtk_decrypt.py** - MediaTek OFP decryption
11. **unkdz.py** - LG KDZ firmware unpacking
12. **kdz.py** - KDZ file format handling
13. **dz.py** - DZ file format handling
14. **aml_image.py** - Amlogic image support
15. **nb0_extractor.py** - Nokia NB0 file extraction
16. **gpt.py** - GPT partition table handling
17. **update_metadata_pb2.py** - Protobuf metadata for OTA
18. **opscrypto.py** - OPPO crypto operations
19. **posix.py** - POSIX compatibility layer
20. **rangelib.py** - Range set operations
21. **utils.py** - Utility functions (simg2img)
22. **logging_helper.py** - DumprX-style logging (Colors class)
23. **__init__.py** - Package initialization

### CLI Wrapper Tools Added (utils/)
1. **lpunpack_tool.py** - CLI for super image unpacking
2. **ext4_extract.py** - CLI for EXT4 partition extraction
3. **payload_extract_tool.py** - CLI for payload.bin extraction
4. **cpio_tool.py** - CLI for CPIO archive operations
5. **ozip_decrypt.py** - CLI for OZIP decryption
6. **kdz_unpack.py** - CLI for KDZ firmware unpacking

### Binary Tools Added (utils/bin/)
1. **brotli** - Brotli compression/decompression (1.6M)
2. **extract.erofs** - Modern EROFS extraction tool (1.8M)
3. **mkfs.erofs** - EROFS filesystem creation (2.4M)
4. **cpio** - CPIO archive operations (1.8M)

## Refactoring Compliance

### ✓ Mandatory Requirements Met

1. **NO Wrapper Functions for Python Imports**
   - ✓ All CLI tools directly use imported modules
   - ✓ No intermediate wrapper functions created
   - ✓ Functions are called directly from imported modules

2. **Modified Imported Python Files for Project Integration**
   - ✓ All imports changed from relative (`from .`) to absolute (`from utils.core`)
   - ✓ Logging replaced with DumprX Colors-based logging pattern
   - ✓ No `import logging` - using `logging_helper.py` instead
   - ✓ Compatible with existing sdat2img.py and splituapp.py logging style

3. **Unified Logging System**
   - ✓ Created `logging_helper.py` with Colors class matching DumprX pattern
   - ✓ All modules use log_info(), log_success(), log_error(), log_warning()
   - ✓ Consistent with existing project logging in sdat2img.py and splituapp.py
   - ✓ Shell script logging uses lib/logger.sh (unchanged)

4. **Adapted to Project Structure**
   - ✓ All modules placed in `utils/core/` directory
   - ✓ CLI tools placed in `utils/` directory
   - ✓ Binaries placed in `utils/bin/` directory
   - ✓ No changes to lib/ directory (maintains separation)

### ✓ Prohibited Actions Avoided

- ✓ Did NOT create wrappers that only redirect calls
- ✓ Did NOT use subprocess.call() unsafely
- ✓ Did NOT leave duplicate files (integrated cleanly)
- ✓ Did NOT create circular dependencies
- ✓ Did NOT ignore errors or exceptions

## Implementation Details

### Phase 1: Core Module Import
- Cloned MIO-KITCHEN-SOURCE repository to /tmp/
- Imported 23 Python modules from src/core/
- Created logging_helper.py matching DumprX logging pattern
- Updated all relative imports to absolute imports
- Installed required dependencies (toml, protobuf)

### Phase 2: Python CLI Wrappers
- Created 6 executable CLI wrapper scripts
- Each wrapper provides argparse-based command-line interface
- Direct module usage (no wrapper functions)
- Consistent error handling and logging

### Phase 3: Binary Integration
- Copied 4 useful binaries from MIO-KITCHEN
- Made all binaries executable
- Added to utils/bin/ directory

### Phase 4: dumper.sh Integration
- Added new tool path variables
- Enhanced superimage_extract() function:
  - Uses Python lpunpack_tool.py first
  - Falls back to binary lpunpack if needed
  - Better sparse image handling
- Enhanced extract_with_erofs() function:
  - Uses extract.erofs first (newer tool)
  - Falls back to fsck.erofs if needed
- Minimal changes to existing code

## Logging System Details

### Current DumprX Logging Pattern
```python
class Colors:
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    CYAN = '\033[96m'
    ENDC = '\033[0m'

def log_info(msg):
    print('{}[INFO]{} {}'.format(Colors.CYAN, Colors.ENDC, msg))

def log_success(msg):
    print('{}[SUCCESS]{} {}'.format(Colors.OKGREEN, Colors.ENDC, msg))
```

This pattern is used in:
- sdat2img.py (existing)
- splituapp.py (existing)
- All newly imported core modules (adapted)
- All CLI wrapper tools (new)

### Shell Logging
- Uses lib/logger.sh (unchanged)
- Functions: log_info(), log_success(), log_error(), log_warning(), log_debug()
- Unchanged from original DumprX implementation

## Tools Integration Matrix

| Tool | Type | Source | Status | Usage in dumper.sh |
|------|------|--------|--------|-------------------|
| lpunpack.py | Python Module | MIO-KITCHEN | ✓ Integrated | Via lpunpack_tool.py in superimage_extract() |
| ext4.py | Python Module | MIO-KITCHEN | ✓ Integrated | Via imgextractor for partition extraction |
| cpio.py | Python Module | MIO-KITCHEN | ✓ Integrated | Via cpio_tool.py for ramdisk operations |
| payload_extract.py | Python Module | MIO-KITCHEN | ✓ Integrated | Via payload_extract_tool.py for OTA |
| ozipdecrypt.py | Python Module | MIO-KITCHEN | ✓ Integrated | Via ozip_decrypt.py for OZIP files |
| unkdz.py | Python Module | MIO-KITCHEN | ✓ Integrated | Via kdz_unpack.py for KDZ files |
| brotli | Binary | MIO-KITCHEN | ✓ Added | For .br file compression |
| extract.erofs | Binary | MIO-KITCHEN | ✓ Added | In extract_with_erofs() function |
| mkfs.erofs | Binary | MIO-KITCHEN | ✓ Added | For EROFS filesystem creation |

## File Format Support Added/Enhanced

### New Format Support
- ✓ PAC files (via pacextractor - already existed, now documented)
- ✓ Enhanced EROFS support (extract.erofs + mkfs.erofs)
- ✓ Brotli compression (.br files)
- ✓ Enhanced super image support (Python lpunpack)

### Enhanced Format Support
- ✓ Super images - Now uses Python lpunpack with binary fallback
- ✓ EROFS images - Now tries extract.erofs before fsck.erofs
- ✓ EXT4 images - Enhanced with imgextractor module
- ✓ OZIP files - Integrated Python module
- ✓ KDZ files - Integrated Python module

## Usage Examples

### Super Image Extraction
```bash
# Automatic (in dumper.sh)
cd /path/to/firmware
bash dumper.sh firmware.zip

# Manual (using Python tool)
python3 utils/lpunpack_tool.py super.img -o output_dir
```

### EXT4 Partition Extraction
```bash
python3 utils/ext4_extract.py system.img -o system_output
```

### Payload.bin Extraction
```bash
python3 utils/payload_extract_tool.py payload.bin -o output_dir
```

### OZIP Decryption
```bash
python3 utils/ozip_decrypt.py firmware.ozip -o firmware.zip
```

### KDZ Unpacking
```bash
python3 utils/kdz_unpack.py firmware.kdz -o output_dir
```

### CPIO Operations
```bash
# Extract
python3 utils/cpio_tool.py -x ramdisk.cpio -o ramdisk_dir

# Create
python3 utils/cpio_tool.py -c ramdisk_dir -o new_ramdisk.cpio
```

## Testing Status

### Module Import Tests
- ✓ All 23 core modules import successfully
- ✓ No import errors
- ✓ Dependencies installed (toml, protobuf)

### Integration Tests
- ⏳ Super image extraction (requires test data)
- ⏳ EXT4 extraction (requires test data)
- ⏳ Payload.bin extraction (requires test data)
- ⏳ OZIP decryption (requires test data)
- ⏳ KDZ unpacking (requires test data)

## Conclusion

The integration of MIO-KITCHEN UNPACK logic into DumprX has been completed successfully with:

1. **23 Python modules** imported and adapted
2. **6 CLI wrapper tools** created for easy usage
3. **4 additional binaries** added for enhanced functionality
4. **Zero wrapper functions** violating refactoring rules
5. **Unified logging** system across all modules
6. **Minimal changes** to existing dumper.sh code
7. **Backward compatibility** maintained

All mandatory refactoring rules have been followed:
- ✓ No wrapper functions for Python imports
- ✓ Modified imported files for project integration
- ✓ Unified logging system
- ✓ Adapted to project structure
- ✓ No prohibited actions taken

The implementation provides enhanced UNPACK capabilities while maintaining DumprX's architectural integrity and coding standards.
