#!/bin/bash

# DumprX Git Upload Library
# Handles large firmware dumps with smart chunking and Git LFS support

# Source dependencies
if ! command -v log_info &> /dev/null; then
	source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"
fi

if ! command -v util_command_exists &> /dev/null; then
	source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"
fi

# Git configuration for large repositories
function git_configure_large_repo() {
	local repo_dir="${1:-.}"
	
	log_step "Configuring git for large repository"
	
	cd "${repo_dir}" || return 1
	
	# Increase buffer sizes
	git config http.postBuffer 524288000        # 500MB
	git config http.maxRequestBuffer 524288000  # 500MB
	
	# Timeout settings
	git config http.lowSpeedLimit 0
	git config http.lowSpeedTime 999999
	
	# Pack settings to reduce memory usage
	git config pack.windowMemory 256m
	git config pack.packSizeLimit 256m
	git config pack.deltaCacheSize 128m
	git config pack.threads 1
	
	# Compression settings
	git config core.compression 0
	git config core.looseCompression 0
	
	# Large file settings
	git config core.bigFileThreshold 50m
	
	# Network retry settings
	git config http.retryDelay 5
	git config http.retries 10
	
	log_success "Git configured for large repository"
}

# Initialize Git LFS for large files
function git_lfs_init() {
	local repo_dir="${1:-.}"
	
	log_step "Initializing Git LFS"
	
	cd "${repo_dir}" || return 1
	
	# Check if git-lfs is installed
	if ! util_command_exists git-lfs; then
		log_warn "Git LFS not installed, large files may cause push failures"
		return 1
	fi
	
	# Initialize LFS
	git lfs install 2>/dev/null || log_warn "Git LFS already initialized"
	
	# Track large file types commonly found in firmware
	local lfs_patterns=(
		"*.so"
		"*.so.*"
		"*.apk"
		"*.jar"
		"*.ttf"
		"*.otf"
		"*.ttc"
		"*.dat"
		"*.bin"
		"*.img"
		"*.prop"
	)
	
	for pattern in "${lfs_patterns[@]}"; do
		git lfs track "${pattern}" 2>/dev/null
	done
	
	# Track files larger than 50MB
	git lfs track "*.{png,jpg,jpeg,gif,mp4,mp3,webp,mkv}" 2>/dev/null
	
	log_success "Git LFS initialized"
}

# Split files larger than threshold
function git_split_large_files() {
	local repo_dir="${1:-.}"
	local max_size="${2:-50M}"  # 50MB default
	local part_size="${3:-45M}"  # 45MB parts
	
	log_step "Checking for files larger than ${max_size}"
	
	cd "${repo_dir}" || return 1
	
	# Find large files
	local large_files
	large_files=$(find . -type f -size "+${max_size}" 2>/dev/null | grep -v "\.git")
	
	if [[ -z "${large_files}" ]]; then
		log_info "No files larger than ${max_size} found"
		return 0
	fi
	
	log_info "Found $(echo "${large_files}" | wc -l) large files, creating split script"
	
	# Create join script
	echo '#!/bin/bash' > join_split_files.sh
	echo '# Script to join split files' >> join_split_files.sh
	echo '' >> join_split_files.sh
	
	while IFS= read -r file; do
		if [[ -f "${file}" ]]; then
			log_debug "Splitting: ${file}"
			
			# Split file
			split -b "${part_size}" "${file}" "${file}."
			
			# Add to join script
			echo "cat ${file}.* > ${file} 2>/dev/null" >> join_split_files.sh
			echo "rm -f ${file}.* 2>/dev/null" >> join_split_files.sh
			
			# Remove original
			rm -f "${file}"
		fi
	done <<< "${large_files}"
	
	chmod +x join_split_files.sh 2>/dev/null
	
	log_success "Large files split successfully"
}

# Intelligent commit chunking
function git_commit_chunks() {
	local repo_dir="${1:-.}"
	local max_files_per_commit="${2:-1000}"
	local max_size_per_commit="${3:-100M}"  # 100MB per commit
	
	log_step "Creating chunked commits"
	
	cd "${repo_dir}" || return 1
	
	# Get list of files to commit
	local files_to_add
	files_to_add=$(git ls-files --others --exclude-standard)
	
	if [[ -z "${files_to_add}" ]]; then
		log_info "No new files to commit"
		return 0
	fi
	
	local total_files
	total_files=$(echo "${files_to_add}" | wc -l)
	log_info "Found ${total_files} files to commit"
	
	local chunk_num=0
	local current_chunk_files=()
	local current_chunk_size=0
	local files_in_chunk=0
	
	while IFS= read -r file; do
		if [[ ! -f "${file}" ]]; then
			continue
		fi
		
		local file_size
		file_size=$(stat -c%s "${file}" 2>/dev/null || stat -f%z "${file}" 2>/dev/null || echo 0)
		
		# Check if we need to commit current chunk
		local should_commit=false
		
		if [[ ${files_in_chunk} -ge ${max_files_per_commit} ]]; then
			should_commit=true
			log_debug "Chunk limit reached (files)"
		elif [[ ${current_chunk_size} -ge $(numfmt --from=iec "${max_size_per_commit}" 2>/dev/null || echo 104857600) ]]; then
			should_commit=true
			log_debug "Chunk limit reached (size)"
		fi
		
		if [[ "${should_commit}" == "true" ]] && [[ ${files_in_chunk} -gt 0 ]]; then
			((chunk_num++))
			log_info "Committing chunk ${chunk_num} (${files_in_chunk} files, $(numfmt --to=iec ${current_chunk_size} 2>/dev/null || echo ${current_chunk_size}) bytes)"
			
			# Add and commit this chunk
			for chunk_file in "${current_chunk_files[@]}"; do
				git add "${chunk_file}"
			done
			
			git commit -m "Add firmware files (chunk ${chunk_num}/${total_files} files)" -q || log_warn "Commit failed for chunk ${chunk_num}"
			
			# Reset chunk
			current_chunk_files=()
			current_chunk_size=0
			files_in_chunk=0
		fi
		
		# Add file to current chunk
		current_chunk_files+=("${file}")
		current_chunk_size=$((current_chunk_size + file_size))
		((files_in_chunk++))
		
	done <<< "${files_to_add}"
	
	# Commit remaining files
	if [[ ${files_in_chunk} -gt 0 ]]; then
		((chunk_num++))
		log_info "Committing final chunk ${chunk_num} (${files_in_chunk} files)"
		
		for chunk_file in "${current_chunk_files[@]}"; do
			git add "${chunk_file}"
		done
		
		git commit -m "Add firmware files (final chunk)" -q || log_warn "Commit failed for final chunk"
	fi
	
	log_success "Created ${chunk_num} commits"
}

# Push with advanced retry logic
function git_push_with_retry() {
	local repo_dir="${1:-.}"
	local remote="${2:-origin}"
	local branch="$3"  # No default - branch must be specified
	local max_retries="${4:-10}"
	
	# Validate branch parameter
	if [[ -z "${branch}" ]]; then
		log_error "Branch name is required for git_push_with_retry"
		log_error "Usage: git_push_with_retry <repo_dir> <remote> <branch> [max_retries]"
		return 1
	fi
	
	log_step "Pushing to ${remote}/${branch}"
	
	cd "${repo_dir}" || return 1
	
	# Check if branch exists and has commits
	if ! git rev-parse --verify "${branch}" >/dev/null 2>&1; then
		log_error "Branch '${branch}' does not exist"
		return 1
	fi
	
	# Check if there are any commits on the branch
	if ! git rev-parse "${branch}" >/dev/null 2>&1; then
		log_error "Branch '${branch}' has no commits"
		return 1
	fi
	
	# Check if remote tracking branch exists
	local has_upstream=false
	if git rev-parse --verify "${remote}/${branch}" >/dev/null 2>&1; then
		has_upstream=true
		log_debug "Remote tracking branch ${remote}/${branch} exists"
	else
		log_debug "No remote tracking branch - will create on first push"
	fi
	
	local attempt=1
	local delay=5
	local max_delay=300  # 5 minutes max
	
	while [[ ${attempt} -le ${max_retries} ]]; do
		log_info "Push attempt ${attempt}/${max_retries}"
		
		# Build push command - use -u flag only on first push
		local push_cmd="git push --progress"
		if [[ "${has_upstream}" == "false" ]]; then
			push_cmd="${push_cmd} -u"
		fi
		push_cmd="${push_cmd} ${remote} ${branch}"
		
		# Try to push with progress
		if eval "${push_cmd}" 2>&1 | tee /tmp/git_push_$$.log; then
			log_success "Push successful on attempt ${attempt}"
			rm -f /tmp/git_push_$$.log
			return 0
		fi
		
		local exit_code=$?
		
		# Check for specific errors
		if grep -q "src refspec.*does not match any" /tmp/git_push_$$.log; then
			log_error "Branch ${branch} has no commits or does not exist"
			log_info "Make sure you have committed changes before pushing"
			rm -f /tmp/git_push_$$.log
			return 1
		elif grep -q "HTTP 500" /tmp/git_push_$$.log || grep -q "HTTP 502" /tmp/git_push_$$.log || grep -q "HTTP 503" /tmp/git_push_$$.log; then
			log_warn "Server error detected, will retry"
		elif grep -q "larger than.*http.postBuffer" /tmp/git_push_$$.log; then
			log_warn "Buffer size issue, increasing buffer"
			git config http.postBuffer 1048576000  # Increase to 1GB
		elif grep -q "RPC failed" /tmp/git_push_$$.log; then
			log_warn "RPC failed, trying alternative method"
			# Try pushing with shallow clone
			git config http.version HTTP/1.1
		elif grep -q "failed to push some refs" /tmp/git_push_$$.log; then
			log_warn "Push rejected - checking for diverged history"
			# Try force with lease for safety
			if [[ "${has_upstream}" == "true" ]]; then
				log_warn "Attempting push with --force-with-lease"
				if git push --force-with-lease --progress "${remote}" "${branch}" 2>&1; then
					log_success "Force push successful"
					rm -f /tmp/git_push_$$.log
					return 0
				fi
			fi
		fi
		
		if [[ ${attempt} -ge ${max_retries} ]]; then
			log_error "Push failed after ${max_retries} attempts"
			log_info "Last error output:"
			tail -20 /tmp/git_push_$$.log | while read -r line; do
				log_error "  ${line}"
			done
			rm -f /tmp/git_push_$$.log
			return 1
		fi
		
		log_info "Waiting ${delay} seconds before retry..."
		sleep "${delay}"
		
		# Exponential backoff with max cap
		delay=$((delay * 2))
		if [[ ${delay} -gt ${max_delay} ]]; then
			delay=${max_delay}
		fi
		
		((attempt++))
	done
	
	rm -f /tmp/git_push_$$.log
	return 1
}

# Alternative push method using shallow clone
function git_push_shallow() {
	local repo_dir="${1:-.}"
	local remote="${2:-origin}"
	local branch="$3"  # No default - branch must be specified
	
	# Validate branch parameter
	if [[ -z "${branch}" ]]; then
		log_error "Branch name is required for git_push_shallow"
		return 1
	fi
	
	log_step "Attempting shallow push"
	
	cd "${repo_dir}" || return 1
	
	# Create a shallow clone
	git config core.compression 9
	
	# Push with atomic and force-with-lease for safety
	if git push --progress --atomic "${remote}" "${branch}"; then
		log_success "Shallow push successful"
		return 0
	else
		log_error "Shallow push failed"
		return 1
	fi
}

# Push commits in batches
function git_push_batches() {
	local repo_dir="${1:-.}"
	local remote="${2:-origin}"
	local branch="$3"  # No default - branch must be specified
	local commits_per_batch="${4:-10}"
	
	# Validate branch parameter
	if [[ -z "${branch}" ]]; then
		log_error "Branch name is required for git_push_batches"
		return 1
	fi
	
	log_step "Pushing commits in batches"
	
	cd "${repo_dir}" || return 1
	
	# Get list of commits to push
	local commits
	commits=$(git rev-list --reverse "${remote}/${branch}..${branch}" 2>/dev/null)
	
	if [[ -z "${commits}" ]]; then
		log_info "No commits to push"
		return 0
	fi
	
	local total_commits
	total_commits=$(echo "${commits}" | wc -l)
	log_info "Found ${total_commits} commits to push"
	
	local batch_num=0
	local commits_in_batch=0
	
	while IFS= read -r commit; do
		((commits_in_batch++))
		
		if [[ ${commits_in_batch} -ge ${commits_per_batch} ]]; then
			((batch_num++))
			log_info "Pushing batch ${batch_num}"
			
			if ! git push --progress "${remote}" "${commit}:refs/heads/${branch}"; then
				log_error "Failed to push batch ${batch_num}"
				return 1
			fi
			
			commits_in_batch=0
			sleep 2  # Brief pause between batches
		fi
	done <<< "${commits}"
	
	# Push remaining commits
	if [[ ${commits_in_batch} -gt 0 ]]; then
		((batch_num++))
		log_info "Pushing final batch ${batch_num}"
		git push --progress "${remote}" "${branch}" || return 1
	fi
	
	log_success "All batches pushed successfully"
}

# Main upload function
function git_upload_dump() {
	local repo_dir="$1"
	local remote_url="$2"
	local branch="$3"  # No default - branch must be specified
	local use_lfs="${4:-true}"
	
	# Validate required parameters
	if [[ -z "${branch}" ]]; then
		log_error "Branch name is required for git_upload_dump"
		log_error "Usage: git_upload_dump <repo_dir> <remote_url> <branch> [use_lfs]"
		return 1
	fi
	
	log_header "Uploading Firmware Dump to GitHub"
	log_info "Target branch: ${branch}"
	
	cd "${repo_dir}" || {
		log_fatal "Cannot access repository directory: ${repo_dir}"
		return 1
	}
	
	# Step 1: Configure git
	git_configure_large_repo "${repo_dir}" || return 1
	
	# Step 2: Initialize LFS if requested
	if [[ "${use_lfs}" == "true" ]]; then
		git_lfs_init "${repo_dir}"
	fi
	
	# Step 3: Split large files if needed
	git_split_large_files "${repo_dir}" "100M" "95M"
	
	# Step 4: Create chunked commits
	git_commit_chunks "${repo_dir}" 500 "50M"
	
	# Step 5: Add remote if not exists
	if ! git remote get-url origin &>/dev/null; then
		log_info "Adding remote: ${remote_url}"
		git remote add origin "${remote_url}"
	fi
	
	# Step 6: Try different push strategies
	log_step "Attempting to push to GitHub"
	
	# Strategy 1: Normal push with retry
	if git_push_with_retry "${repo_dir}" "origin" "${branch}" 10; then
		return 0
	fi
	
	log_warn "Normal push failed, trying batch push"
	
	# Strategy 2: Batch push
	if git_push_batches "${repo_dir}" "origin" "${branch}" 5; then
		return 0
	fi
	
	log_warn "Batch push failed, trying shallow push"
	
	# Strategy 3: Shallow push
	if git_push_shallow "${repo_dir}" "origin" "${branch}"; then
		return 0
	fi
	
	log_error "All push strategies failed"
	log_info "Consider using Git LFS or splitting the repository into multiple repos"
	
	return 1
}
