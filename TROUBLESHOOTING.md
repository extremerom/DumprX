# Troubleshooting HTTP 500 Errors

## Problem
When pushing large firmware dumps to GitHub, you may encounter errors like:

```
error: RPC failed; HTTP 500 curl 22 The requested URL returned error: 500
send-pack: unexpected disconnect while reading sideband packet
```

## Root Cause
These errors occur when:
1. Individual commits are too large (>100MB even with Git LFS)
2. Network connections timeout during long uploads
3. GitHub servers are overloaded or experiencing issues
4. Pack files exceed size limits

## Solutions Implemented

### 1. Retry Logic with Exponential Backoff
The script now automatically retries failed pushes up to 5 times with increasing wait times:
- Attempt 1: Immediate
- Attempt 2: Wait 10 seconds
- Attempt 3: Wait 20 seconds
- Attempt 4: Wait 40 seconds
- Attempt 5: Wait 80 seconds

### 2. Improved Commit Splitting
Files are now split into smaller batches:
- APK files: 50 files per commit
- System directory: 8 parts
- Vendor directory: 5 parts
- Remaining files: 100 files per commit

### 3. Git Configuration Optimizations
The script sets these configurations to handle large repositories better:
```bash
git config --global http.postBuffer 524288000      # 500MB buffer
git config --global http.lowSpeedLimit 0           # No speed limit
git config --global http.lowSpeedTime 999999       # Long timeout
git config --global pack.windowMemory 256m         # Reduce memory
git config --global pack.packSizeLimit 256m        # Limit pack size
git config --global core.compression 0             # Faster ops
```

## Manual Troubleshooting

If you still encounter errors after these fixes:

### 1. Check Your Network Connection
```bash
# Test your upload speed (multiple options)
# Option 1: Using speedtest-cli (install with: pip install speedtest-cli)
speedtest-cli

# Option 2: Using fast.com (requires curl)
curl -s https://fast.com | grep -o '[0-9]\+ Mbps'

# Option 3: Check network stability
ping -c 10 github.com
```

### 2. Reduce Batch Sizes
Edit `dumper.sh` and reduce these values:
- Line ~1267: Change `batch_size=50` to `batch_size=25`
- Line ~1348: Change `file_batch_size=100` to `file_batch_size=50`

### 3. Use SSH Instead of HTTPS
If using GitHub:
```bash
# In dumper.sh, change the remote URL to SSH
git remote set-url origin git@github.com:${GIT_ORG}/${repo}.git
```

### 4. Split Large Files Before Committing
The script already handles this, but you can manually verify:
```bash
# Find files larger than 50MB
find . -type f -size +50M -not -path "./.git/*"

# Split large files if needed
split -b 47M large_file.img large_file.img.
```

### 5. Use Git LFS for All Large Files
```bash
# Track all files larger than 50MB with Git LFS
find . -type f -size +50M -not -path "./.git/*" -exec git lfs track {} \;
```

### 6. Check GitHub Status
Visit https://www.githubstatus.com/ to check if GitHub is experiencing issues.

## Prevention Tips

1. **Use Git LFS**: Always enable Git LFS for firmware dumps
2. **Split commits**: Keep individual commits under 100MB
3. **Monitor progress**: Watch the push output for errors
4. **Use stable network**: Avoid pushing on unstable connections
5. **Be patient**: Large pushes can take hours

## Getting Help

If you continue to experience issues:
1. Check the script output for specific error messages
2. Review GitHub Actions logs if using the workflow
3. Open an issue with:
   - Full error message
   - Size of your dump
   - Network conditions
   - Git version (`git --version`)

## Related Documentation
- [Git LFS Documentation](https://git-lfs.github.com/)
- [GitHub Push Limits](https://docs.github.com/en/repositories/working-with-files/managing-large-files)
- [Git Configuration](https://git-scm.com/docs/git-config)
