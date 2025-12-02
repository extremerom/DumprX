# Git Upload System - Handling Large Firmware Dumps

This document explains the git upload system for handling large firmware dumps.

## Problem

When uploading large firmware dumps to GitHub, you may encounter:

```
error: RPC failed; HTTP 500 curl 22 The requested URL returned error: 500
send-pack: unexpected disconnect while reading sideband packet
fatal: the remote end hung up unexpectedly
```

This happens because:
1. **Large files** - Font files, binaries, APKs can be very large
2. **GitHub limits** - 100MB file limit, 2GB repository limit (recommended)

## Solutions Implemented

### 1. Git LFS (Large File Storage)

Automatically tracks large files:

```bash
# Files larger than 100MB are automatically tracked with LFS
find . -type f -not -path ".git/*" -size +100M -exec git lfs track {} \;
```

**LFS Lock Verification:** The script automatically enables Git LFS lock verification for the remote repository, preventing concurrent modifications to large binary files.

### 2. File Splitting

Files larger than 62MB are split into smaller parts:
http.lowSpeedLimit = 0
http.lowSpeedTime = 999999

# Memory optimization
pack.windowMemory = 256m
pack.packSizeLimit = 256m
pack.threads = 1

# Network retries
http.retryDelay = 5
http.retries = 10
```

### 3. Intelligent Commit Chunking

Splits files into smaller commits:

```bash
# APK files: 30 per commit (reduced from 50)
# Other files: 100 per commit
# Maximum commit size: ~50MB
```

### 4. Advanced Retry Logic

Exponential backoff with:
- Initial delay: 5 seconds
- Maximum delay: 5 minutes
- Maximum attempts: 10
- Error analysis and automatic adjustment

### 5. File Splitting

Files > 100MB are split into smaller parts:

```bash
# Original file: large_file.bin (150MB)
# Split into: large_file.bin.aa, large_file.bin.ab, ... (95MB each)
# Join script: join_split_files.sh (included in repo)
```

## Usage

### Automatic (Recommended)

The improved system is automatically used when you run dumper.sh:

```bash
./dumper.sh firmware.zip
```

The script will:
1. Configure git optimally
2. Initialize Git LFS
3. Track large files
4. Split files if needed
5. Create chunked commits
6. Push with retry logic

### Manual Control

Use the git_upload library directly:

```bash
source lib/git_upload.sh

# Configure repository
git_configure_large_repo /path/to/repo

# Initialize LFS
git_lfs_init /path/to/repo

# Split large files
git_split_large_files /path/to/repo "100M" "95M"

# Create chunked commits
git_commit_chunks /path/to/repo 500 "50M"

# Push with retry
git_push_with_retry /path/to/repo origin main 10

# Or use the all-in-one function
git_upload_dump /path/to/repo "https://github.com/user/repo.git" main true
```

## Configuration Options

### Environment Variables

```bash
# Maximum retry attempts (default: 10)
export DUMPRX_GIT_MAX_RETRIES=10

# Files per commit (default: 500)
export DUMPRX_GIT_FILES_PER_COMMIT=500

# Size per commit (default: 50M)
export DUMPRX_GIT_SIZE_PER_COMMIT="50M"

# Enable/disable LFS (default: true)
export DUMPRX_GIT_USE_LFS=true
```

### In Configuration File

```ini
# .dumprx.conf
git_max_retries = 10
git_files_per_commit = 500
git_size_per_commit = 50M
git_use_lfs = true
```

## Troubleshooting

### Still Getting HTTP 500 Errors?

1. **Check file sizes:**
   ```bash
   find . -type f -size +50M | sort
   ```

2. **Ensure Git LFS is working:**
   ```bash
   git lfs ls-files
   git lfs status
   ```

3. **Check repository size:**
   ```bash
   du -sh .git
   ```

4. **Try smaller commits:**
   ```bash
   export DUMPRX_GIT_FILES_PER_COMMIT=100
   export DUMPRX_GIT_SIZE_PER_COMMIT="25M"
   ```

### Files Still Too Large?

Split them manually:

```bash
# Split file into 50MB chunks
split -b 50M large_file.bin large_file.bin.

# Create join script
echo '#!/bin/bash' > join_file.sh
echo 'cat large_file.bin.* > large_file.bin' >> join_file.sh
echo 'rm large_file.bin.*' >> join_file.sh
chmod +x join_file.sh
```

### Push Still Failing?

Try alternative strategies:

```bash
# Strategy 1: Push in smaller batches (commits)
git_push_batches /path/to/repo origin main 5

# Strategy 2: Shallow push
git_push_shallow /path/to/repo origin main

# Strategy 3: Split into multiple repositories
# firmware-system, firmware-vendor, firmware-apps, etc.
```

## Best Practices

### Before Pushing

1. **Check repository size:**
   ```bash
   du -sh out/
   ```

2. **Identify large files:**
   ```bash
   find out/ -type f -size +50M
   ```

3. **Ensure LFS is configured:**
   ```bash
   git lfs track "*.ttf" "*.otf" "*.apk"
   ```

4. **Clean up unnecessary files:**
   ```bash
   find . -name "*.log" -delete
   find . -name "__pycache__" -delete
   ```

### During Push

1. **Monitor progress:**
   ```bash
   # Logs are written to /tmp/git_push_$$.log
   tail -f /tmp/git_push_*.log
   ```

2. **Check network:**
   ```bash
   ping github.com
   speedtest-cli
   ```

3. **Be patient:**
   - Large repositories can take hours to push
   - Don't interrupt the process
   - Retries are automatic

### After Push

1. **Verify upload:**
   ```bash
   git ls-remote origin
   ```

2. **Check LFS files:**
   ```bash
   git lfs ls-files
   ```

3. **Verify on GitHub:**
   - Check repository size
   - Ensure all files are present
   - Test downloading

## File Size Limits

### GitHub Limits

- **File size:** 100MB (hard limit)
- **LFS file size:** 2GB per file
- **Repository size:** 5GB (recommended), 100GB (absolute max)
- **LFS storage:** 1GB free, more with subscription

### Our Limits

- **Small commit:** < 50MB (fast)
- **Medium commit:** 50-100MB (slower)
- **Large commit:** > 100MB (split required)

## Examples

### Example 1: Font Files

For files like `NotoSansMyanmar-Medium.otf`:

```bash
# Automatically tracked by LFS (*.otf pattern)
# No special action needed
./dumper.sh firmware.zip
```

### Example 2: Very Large APK

For a 150MB APK:

```bash
# Will be automatically:
# 1. Tracked by LFS
# 2. Split into smaller parts if needed
# 3. Committed separately
./dumper.sh firmware.zip
```

### Example 3: Many Small Files

For 10,000 small files:

```bash
# Will be automatically:
# 1. Grouped into batches of 500
# 2. Committed in chunks
# 3. Pushed incrementally
./dumper.sh firmware.zip
```

## Alternative Solutions

If all else fails:

### 1. Use GitLab

GitLab has higher limits:

```bash
# Set GitLab instead of GitHub
echo "gitlab.com" > .gitlab_instance
echo "YOUR_TOKEN" > .gitlab_token
echo "YOUR_GROUP" > .gitlab_group
./dumper.sh firmware.zip
```

### 2. Split Repository

Create separate repos:

```bash
# firmware-system
# firmware-vendor
# firmware-apps
# firmware-fonts
```

### 3. Use Git Bundles

For offline transfer:

```bash
git bundle create firmware.bundle --all
# Transfer firmware.bundle
git clone firmware.bundle firmware
```

### 4. Use Alternative Hosting

- **Gitea** - Self-hosted, unlimited
- **BitBucket** - 2GB LFS free
- **Azure DevOps** - Unlimited private repos

## Performance Tips

1. **Faster pushes:**
   ```bash
   git config core.compression 0  # Disable compression
   git config pack.threads 1      # Reduce CPU usage
   ```

2. **Reduce network usage:**
   ```bash
   git config http.postBuffer 524288000  # Larger buffer
   git config pack.windowMemory 128m     # Less memory
   ```

3. **Parallel pushes (use carefully):**
   ```bash
   # Not recommended for large files
   git push --jobs=2
   ```

## Monitoring

Check push status:

```bash
# Watch git process
watch -n 1 'ps aux | grep git'

# Monitor network
nethogs
iftop

# Check disk usage
df -h
du -sh .git/objects
```

## Support

If you still have issues:

1. Check logs: `dumprx.log`
2. Check git logs: `/tmp/git_push_*.log`
3. Enable verbose mode: `./dumper.sh --verbose firmware.zip`
4. Open an issue with:
   - Error message
   - Repository size
   - Large file list
   - Git LFS status

## References

- [Git LFS Documentation](https://git-lfs.github.com/)
- [GitHub Size Limits](https://docs.github.com/en/repositories/working-with-files/managing-large-files)
- [Git Configuration](https://git-scm.com/docs/git-config)
