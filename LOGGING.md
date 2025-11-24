# DumprX - Advanced Logging and Configuration

This document describes the new logging system and configuration features added to DumprX.

## New Logging System

DumprX now features a comprehensive logging system with multiple levels, colored output, timestamps, and file logging support.

### Log Levels

The logging system supports the following levels (in order of severity):

- **DEBUG**: Detailed diagnostic information
- **INFO**: General informational messages
- **SUCCESS**: Success confirmations
- **WARN**: Warning messages for non-critical issues
- **ERROR**: Error messages for failures
- **FATAL**: Critical errors that cause termination

### Command Line Options

DumprX now supports the following command-line options:

```bash
# Enable verbose (debug) logging
./dumper.sh --verbose firmware.zip
./dumper.sh -v firmware.zip

# Quiet mode (only show errors)
./dumper.sh --quiet firmware.zip
./dumper.sh -q firmware.zip

# Dry run mode (don't actually perform operations)
./dumper.sh --dry-run firmware.zip

# Disable colored output
./dumper.sh --no-colors firmware.zip

# Use specific configuration file
./dumper.sh --config mycustom.conf firmware.zip

# Show help
./dumper.sh --help
./dumper.sh -h
```

### Log File Output

To enable log file output, set the `DUMPRX_LOG_FILE` environment variable:

```bash
export DUMPRX_LOG_FILE=/path/to/dumprx.log
./dumper.sh firmware.zip
```

Or set it in your configuration file (see below).

### Environment Variables

The following environment variables control the logging behavior:

- `DUMPRX_LOG_LEVEL`: Set log level (DEBUG, INFO, WARN, ERROR, FATAL)
- `DUMPRX_LOG_FILE`: Path to log file (empty = no file logging)
- `DUMPRX_LOG_COLORS`: Enable/disable colored output (true/false)
- `DUMPRX_LOG_TIMESTAMP`: Enable/disable timestamps (true/false)
- `DUMPRX_QUIET_MODE`: Quiet mode (true/false)
- `DUMPRX_VERBOSE_MODE`: Verbose mode (true/false)

Example:

```bash
export DUMPRX_LOG_LEVEL=DEBUG
export DUMPRX_LOG_FILE=~/dumprx.log
export DUMPRX_LOG_COLORS=true
./dumper.sh firmware.zip
```

## Configuration File Support

DumprX now supports configuration files for persistent settings.

### Configuration File Locations

DumprX will look for configuration files in the following locations (in order):

1. File specified with `--config` option
2. `.dumprx.conf` in current directory
3. `~/.dumprx.conf` in home directory
4. `~/.config/dumprx/config`
5. `/etc/dumprx/config`

### Creating a Configuration File

Generate an example configuration file:

```bash
# This creates a .dumprx.conf.example file
cat > .dumprx.conf.example << 'EOF'
# DumprX Configuration File

# Logging settings
log_level = INFO
log_file = 
log_colors = true
log_timestamp = true
quiet_mode = false
verbose_mode = false

# Operation settings
dry_run = false
verify_checksums = false
keep_temp = false
max_retries = 3
download_timeout = 3600
enable_summary = true
EOF
```

### Configuration Options

#### Logging Settings

- `log_level`: Log level (DEBUG, INFO, SUCCESS, WARN, ERROR, FATAL)
- `log_file`: Path to log file (leave empty to disable)
- `log_colors`: Enable colored output (true/false)
- `log_timestamp`: Enable timestamps in logs (true/false)
- `quiet_mode`: Only show errors (true/false)
- `verbose_mode`: Show debug messages (true/false)

#### Operation Settings

- `dry_run`: Don't actually perform operations (true/false)
- `verify_checksums`: Verify checksums for downloads (true/false)
- `keep_temp`: Keep temporary files after extraction (true/false)
- `max_retries`: Maximum number of retries for failed operations
- `download_timeout`: Download timeout in seconds
- `enable_summary`: Show summary report at the end (true/false)

### Example Configuration

```ini
# DumprX Configuration
# ~/.dumprx.conf

# Enable debug logging
log_level = DEBUG
log_file = /tmp/dumprx.log
log_colors = true
log_timestamp = true

# Operation settings
verify_checksums = true
keep_temp = false
max_retries = 5
```

## New Features

### Progress Tracking

The new logging system includes several progress tracking features:

- **Step Counter**: Shows current step and total steps
- **Spinner**: Animated spinner for long-running operations
- **Progress Bar**: Visual progress indicator

### Summary Reports

At the end of extraction, DumprX can generate a summary report showing:

- Firmware information
- Extracted partitions
- File sizes
- Extraction time
- Any errors or warnings

Enable summary reports in configuration:

```ini
enable_summary = true
```

### Better Error Handling

The refactored code includes improved error handling with:

- Detailed error messages
- Automatic retries for network operations
- Graceful degradation
- Better cleanup on failure

## Library Architecture

The refactoring introduced a modular library architecture:

### lib/logger.sh

Core logging functionality including:
- Log level management
- Colored output
- Timestamp support
- File logging
- Progress indicators
- Summary reports

### lib/utils.sh

Utility functions including:
- File operations with error handling
- Checksum calculation and verification
- Path manipulation
- Disk space checking
- Command retry logic

### lib/config.sh

Configuration management including:
- Configuration file loading
- Environment variable management
- Configuration validation

### lib/downloaders.sh

Download functionality including:
- Multi-source download support
- Automatic retry logic
- Progress tracking
- Checksum verification

## Migration Guide

### For Users

The new version is backward compatible. Your existing commands will work:

```bash
./dumper.sh firmware.zip
```

To use new features, add options:

```bash
./dumper.sh --verbose firmware.zip
./dumper.sh --dry-run firmware.zip
```

### For Developers

If you've customized DumprX scripts:

1. Source the new libraries in your scripts:
```bash
source "${PROJECT_DIR}/lib/logger.sh"
source "${PROJECT_DIR}/lib/utils.sh"
```

2. Replace `echo` and `printf` with logging functions:
```bash
# Old
echo "Processing file..."
printf "Error: File not found\n"

# New
log_info "Processing file..."
log_error "File not found"
```

3. Use utility functions for file operations:
```bash
# Old
mkdir -p /path/to/dir
cp file1 file2
rm -rf /path

# New
util_mkdir /path/to/dir
util_copy file1 file2
util_remove /path
```

## Troubleshooting

### Log file not being created

Check that you have write permissions to the log file location:

```bash
export DUMPRX_LOG_FILE=~/dumprx.log
```

### Colors not showing

Make sure your terminal supports ANSI colors. If not, disable colors:

```bash
./dumper.sh --no-colors firmware.zip
```

Or in configuration:

```ini
log_colors = false
```

### Too much output

Use quiet mode to only see errors:

```bash
./dumper.sh --quiet firmware.zip
```

### Not enough output

Use verbose mode to see debug messages:

```bash
./dumper.sh --verbose firmware.zip
```

## Examples

### Basic usage with verbose logging

```bash
./dumper.sh --verbose firmware.zip
```

### Download and extract with log file

```bash
export DUMPRX_LOG_FILE=~/extraction.log
./dumper.sh 'https://example.com/firmware.zip'
```

### Dry run to check what would happen

```bash
./dumper.sh --dry-run firmware.zip
```

### Use custom configuration

```bash
./dumper.sh --config ~/my-dumprx.conf firmware.zip
```

### Quiet mode for scripting

```bash
./dumper.sh --quiet firmware.zip && echo "Success!" || echo "Failed!"
```

## Contributing

When contributing to DumprX, please use the new logging system:

1. Use appropriate log levels
2. Provide descriptive messages
3. Include debug logging for troubleshooting
4. Use utility functions for file operations
5. Add error handling with logging

Example:

```bash
log_step "Processing firmware"

if ! util_copy "${source}" "${dest}"; then
    log_error "Failed to copy firmware"
    return 1
fi

log_success "Firmware processed successfully"
```
