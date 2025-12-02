# GitLab SSH Upload Fix - Complete Summary

## Issue Description
The workflow was failing to parse GitLab repository URLs correctly, resulting in "https:" being extracted as the organization name instead of the actual username/group. This caused the GitLab user/group lookup to fail.

Error message:
```
[2025-12-02 19:53:16] ℹ️ INFO: Detected user namespace: https:
[2025-12-02 19:53:16] ✗ ERROR: Could not find user or group: https:
Error: Process completed with exit code 1.
```

## Root Cause Analysis
The sed regex pattern in the workflow:
```bash
GITLAB_DOMAIN=$(echo "$REPO_URL" | sed -E 's|^(https?://|git@)||' | sed -E 's|([^/:]+).*|\1|')
```

The problem was that `|` inside the parentheses was being interpreted as the sed delimiter instead of a regex OR operator, causing the parsing to fail.

## Solutions Implemented

### 1. Fixed URL Parsing (.github/workflows/dump-device.yml)
Replaced the broken sed regex with bash parameter expansion:

```bash
# First, remove protocol prefix (https://, http://, or git@)
TEMP_URL="$REPO_URL"
TEMP_URL="${TEMP_URL#https://}"
TEMP_URL="${TEMP_URL#http://}"
TEMP_URL="${TEMP_URL#git@}"

# Extract domain (everything before first : or /)
GITLAB_DOMAIN=$(echo "$TEMP_URL" | sed -E 's|[:/].*||')
```

**Benefits:**
- More readable and maintainable
- Correctly handles all URL formats
- No delimiter conflicts
- More robust parsing

### 2. Enhanced Logging (dumper.sh)
Added clear log messages to show the upload process:

```bash
log_step "Configuring Git remote with SSH"
log_info "Remote URL: git@${GITLAB_INSTANCE}:${GIT_ORG}/${repo}.git"
git remote add origin git@${GITLAB_INSTANCE}:${GIT_ORG}/${repo}.git

log_info "Setting repository visibility to public (API call)"
curl --request PUT --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" ...

log_header "Pushing Firmware to GitLab via SSH"
log_info "Pushing to git@${GITLAB_INSTANCE}:${GIT_ORG}/${repo}.git"
log_info "Branch: ${branch}"
```

**Benefits:**
- Clear indication that SSH is being used for uploads
- Users can see exactly what URL is being used
- Distinguishes between API calls (with token) and git operations (with SSH)

## Verification

### URL Parsing Tests
All test cases pass successfully:

| Input URL | Expected Instance | Expected Org | Result |
|-----------|------------------|--------------|--------|
| `https://gitlab.com/Eduardob3677/samsung_dm2q.git` | gitlab.com | Eduardob3677 | ✅ PASS |
| `http://gitlab.com/Eduardob3677/samsung_dm2q.git` | gitlab.com | Eduardob3677 | ✅ PASS |
| `git@gitlab.com:Eduardob3677/samsung_dm2q.git` | gitlab.com | Eduardob3677 | ✅ PASS |
| `https://gitlab.example.com/mygroup/myrepo.git` | gitlab.example.com | mygroup | ✅ PASS |
| `git@gitlab.example.com:mygroup/myrepo.git` | gitlab.example.com | mygroup | ✅ PASS |
| `https://gitlab.com/group/subgroup/project.git` | gitlab.com | group | ✅ PASS |

### Token vs SSH Usage

#### GitLab Token (GITLAB_TOKEN) - API Only
✅ Creating repositories via API
✅ Setting repository visibility
✅ Getting user/group information
✅ Checking if firmware already exists
❌ Git push operations (uses SSH)
❌ Git clone operations (uses SSH)

#### SSH Key (GITLAB_SSH_KEY) - Git Operations
✅ All git push operations
✅ Authenticating with GitLab for file uploads
❌ API calls (uses token)

### Security Check
✅ No security issues found by CodeQL
✅ No secrets exposed in code
✅ Token only used for authenticated API calls
✅ SSH key properly configured with correct permissions

### Code Review
✅ No review comments
✅ All changes are minimal and focused
✅ Clear comments and documentation added

## Files Modified
1. `.github/workflows/dump-device.yml` - Fixed URL parsing (8 lines added, 1 line removed)
2. `dumper.sh` - Enhanced logging (11 lines modified)

## Benefits of This Fix

1. **Correct Parsing**: Organization names are now correctly extracted from all GitLab URL formats
2. **SSH for Large Files**: All file uploads use SSH protocol for better reliability with large firmware dumps
3. **Clear Separation**: Token for API calls only, SSH for git operations
4. **Better Debugging**: Users can clearly see which protocol and URL is being used
5. **Multiple Formats**: Supports HTTPS, HTTP, and SSH URL input formats
6. **Custom Instances**: Works with self-hosted GitLab instances

## Testing Recommendations

To test this fix:

1. **User namespace test**: Use URL like `https://gitlab.com/username/repo.git`
2. **Group namespace test**: Use URL with group like `https://gitlab.com/groupname/repo.git`
3. **Custom instance test**: Use custom GitLab like `https://gitlab.example.com/user/repo.git`
4. **SSH URL test**: Use SSH format like `git@gitlab.com:user/repo.git`

Expected behavior:
- Organization name is correctly extracted
- Repository is created via API (using token)
- Files are pushed via SSH (not using token)
- Logs clearly show SSH URL being used

## Conclusion
This fix resolves the GitLab URL parsing issue and ensures that the workflow correctly uses SSH for all file uploads while keeping the token usage restricted to API calls only. The implementation is minimal, focused, and well-tested.
