# DumprX Python Refactoring

## Overview

DumprX has been refactored from Bash to Python for better maintainability, modularity, and cross-platform compatibility.

## Migration Status

### ✅ Completed

- **lib/logger.py** - Logging system with colors, levels, file output
- **lib/utils.py** - File operations, checksums, command execution
- **lib/config.py** - Configuration management
- **dumper.py** - Main extraction tool (structure complete, extraction logic in progress)

### 🚧 In Progress

- Firmware detection and extraction logic
- Image processing functions
- Boot image extraction
- DTBO extraction

### 📋 Original Shell Scripts (deprecated)

- lib/logger.sh (322 lines) → lib/logger.py
- lib/utils.sh (434 lines) → lib/utils.py
- lib/config.sh (270 lines) → lib/config.py
- dumper.sh (2632 lines) → dumper.py

## Usage

### New Python Version

```bash
# Basic usage
python3 dumper.py firmware.zip

# With options
python3 dumper.py --verbose firmware.zip
python3 dumper.py --quiet --config custom.conf firmware.tar.gz
python3 dumper.py --help
```

### Old Bash Version (still available)

```bash
bash dumper.sh firmware.zip
```

## Features & Improvements

### Python Benefits

✅ **Type Safety** - Full type hints throughout  
✅ **Better Error Handling** - Proper exception handling  
✅ **Modularity** - Clean class-based architecture  
✅ **Testability** - Easy to unit test  
✅ **Documentation** - Comprehensive docstrings  
✅ **Cross-platform** - Works on Linux, macOS, Windows (with minor adjustments)

### API Examples

```python
from lib import logger, utils, config

# Logging
logger.info("Processing firmware...")
logger.success("Extraction complete")
logger.step("Extracting partitions")

# Utilities
utils.mkdir("/path/to/dir")
checksum = utils.calculate_checksum("file.img", "sha256")
utils.extract_archive("firmware.zip", "output/")

# Configuration
cfg = config.get_config()
partitions = cfg.get("extraction", "partitions")
cfg.set("general", "verbose", "true")
```

## Requirements

- Python 3.7+
- All existing binary tools (7zz, etc.)
- Python packages: (none currently, may add later)

## Development

### Running Tests

```bash
# Test individual modules
python3 -m lib.logger
python3 -m lib.utils
python3 -m lib.config

# Test main script
python3 dumper.py --help
python3 dumper.py --verbose test_firmware.zip
```

### Code Style

- PEP 8 compliant
- Type hints for all functions
- Docstrings for all public APIs
- Maximum line length: 100 characters

## Migration Guide

### For Users

The Python version maintains the same command-line interface:

**Before:**
```bash
bash dumper.sh firmware.zip
```

**After:**
```bash
python3 dumper.py firmware.zip
```

All options remain the same (`--verbose`, `--quiet`, etc.)

### For Contributors

When adding new features:

1. Use Python modules in `lib/` for shared functionality
2. Follow existing code structure and style
3. Add type hints and docstrings
4. Test with various firmware types

## Backwards Compatibility

- Original `dumper.sh` remains available during transition
- `setup.sh` continues to work (not converted)
- All binary tools and utilities unchanged
- Configuration files compatible

## Future Enhancements

- [ ] Complete firmware extraction logic migration
- [ ] Add Python-based tests
- [ ] Create pip-installable package
- [ ] Add GUI option (PyQt/Tkinter)
- [ ] Windows native support improvements
- [ ] Progress bars for long operations
- [ ] Parallel extraction support

## Contributing

See main project README for contribution guidelines. Python-specific guidelines:

- Follow PEP 8
- Add type hints
- Write docstrings
- Test on Python 3.7+

## License

Same as DumprX project (see main LICENSE file)
