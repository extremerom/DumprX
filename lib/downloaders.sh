#!/bin/bash

# DumprX Downloader Library
# Handles downloading from various sources with retry logic and progress tracking

# Source dependencies
if ! command -v log_info &> /dev/null; then
	source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"
fi

if ! command -v util_command_exists &> /dev/null; then
	source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"
fi

# Download from direct URL using aria2c or wget
function download_direct() {
	local url="$1"
	local output_dir="${2:-.}"
	local filename="${3:-}"
	
	log_info "Downloading from: ${url}"
	
	# Create output directory
	util_mkdir "${output_dir}" || return 1
	cd "${output_dir}" || return 1
	
	# Prepare download command
	local download_cmd
	local -a download_args
	
	if util_command_exists aria2c; then
		log_debug "Using aria2c for download"
		download_cmd="aria2c"
		download_args=(-x16 -s8 --console-log-level=warn --summary-interval=0 --check-certificate=false)
		if [[ -n "${filename}" ]]; then
			download_args+=(-o "${filename}")
		fi
		download_args+=("${url}")
	elif util_command_exists wget; then
		log_debug "Using wget for download"
		download_cmd="wget"
		download_args=(-q --show-progress --progress=bar:force --no-check-certificate)
		if [[ -n "${filename}" ]]; then
			download_args+=(-O "${filename}")
		fi
		download_args+=("${url}")
	elif util_command_exists curl; then
		log_debug "Using curl for download"
		download_cmd="curl"
		download_args=(-L -O)
		if [[ -n "${filename}" ]]; then
			download_args=(-L -o "${filename}")
		fi
		download_args+=("${url}")
	else
		log_error "No download tool available (aria2c, wget, or curl required)"
		return 1
	fi
	
	# Execute download with retry
	if [[ "${DUMPRX_DRY_RUN}" == "true" ]]; then
		log_info "[DRY RUN] Would download: ${url}"
		return 0
	fi
	
	# Use improved output parsing for aria2c
	if [[ "${download_cmd}" == "aria2c" ]]; then
		local attempt=1
		local max_attempts="${DUMPRX_MAX_RETRIES:-3}"
		local delay=5
		local download_success=false
		
		while [[ ${attempt} -le ${max_attempts} ]]; do
			log_debug "Download attempt ${attempt}/${max_attempts}"
			
			local last_progress=""
			local download_result=0
			
			# Run aria2c and parse output in real-time
			"${download_cmd}" "${download_args[@]}" 2>&1 | while IFS= read -r line; do
				# Filter out aria2c summary lines that start with [#
				if [[ "${line}" =~ ^\[#[0-9a-f]+ ]]; then
					# Extract key information from progress line
					# Format: [#gid SIZE/TOTAL(%) CN:X DL:SPEED ETA:TIME]
					local progress_info="${line}"
					
					# Only print progress updates every few lines to reduce clutter
					# Extract percentage if available
					if [[ "${progress_info}" =~ \(([0-9]+)%\) ]]; then
						local percent="${BASH_REMATCH[1]}"
						# Only update every 5%
						if [[ -z "${last_progress}" ]] || [[ $((percent - last_progress)) -ge 5 ]] || [[ "${percent}" == "100" ]]; then
							# Extract useful info: downloaded/total, percentage, speed, ETA
							if [[ "${progress_info}" =~ ([0-9.]+[KMGT]?i?B)/([0-9.]+[KMGT]?i?B)\(([0-9]+)%\).*DL:([0-9.]+[KMGT]?i?B).*ETA:([0-9hms]+) ]]; then
								local downloaded="${BASH_REMATCH[1]}"
								local total="${BASH_REMATCH[2]}"
								local speed="${BASH_REMATCH[4]}"
								local eta="${BASH_REMATCH[5]}"
								
								if [[ "${DUMPRX_LOG_COLORS}" == "true" ]]; then
									printf "\r${LOG_COLOR_CYAN}📥 Progress:${LOG_COLOR_RESET} ${LOG_COLOR_GREEN}%s${LOG_COLOR_RESET}/%s (${LOG_COLOR_BOLD}%s%%${LOG_COLOR_RESET}) ${LOG_COLOR_BLUE}⚡ %s/s${LOG_COLOR_RESET} ${LOG_COLOR_YELLOW}⏱ ETA: %s${LOG_COLOR_RESET}" \
										"${downloaded}" "${total}" "${percent}" "${speed}" "${eta}"
								else
									printf "\r📥 Progress: %s/%s (%s%%) ⚡ %s/s ⏱ ETA: %s" \
										"${downloaded}" "${total}" "${percent}" "${speed}" "${eta}"
								fi
							elif [[ "${progress_info}" =~ ([0-9.]+[KMGT]?i?B)/([0-9.]+[KMGT]?i?B)\(([0-9]+)%\).*DL:([0-9.]+[KMGT]?i?B) ]]; then
								# No ETA available (near completion)
								local downloaded="${BASH_REMATCH[1]}"
								local total="${BASH_REMATCH[2]}"
								local speed="${BASH_REMATCH[4]}"
								
								if [[ "${DUMPRX_LOG_COLORS}" == "true" ]]; then
									printf "\r${LOG_COLOR_CYAN}📥 Progress:${LOG_COLOR_RESET} ${LOG_COLOR_GREEN}%s${LOG_COLOR_RESET}/%s (${LOG_COLOR_BOLD}%s%%${LOG_COLOR_RESET}) ${LOG_COLOR_BLUE}⚡ %s/s${LOG_COLOR_RESET}" \
										"${downloaded}" "${total}" "${percent}" "${speed}"
								else
									printf "\r📥 Progress: %s/%s (%s%%) ⚡ %s/s" \
										"${downloaded}" "${total}" "${percent}" "${speed}"
								fi
							fi
							last_progress="${percent}"
						fi
					fi
				elif [[ "${line}" =~ ^Download\ Results: ]] || [[ "${line}" =~ ^gid ]] || [[ "${line}" =~ ^===== ]] || [[ "${line}" =~ ^Status\ Legend: ]] || [[ "${line}" =~ ^\(OK\): ]]; then
					# Skip these summary header lines
					continue
				elif [[ "${line}" =~ ^[0-9a-f]+\|OK ]]; then
					# Download completed successfully
					printf "\n"
				else
					# For any other output (errors, warnings), pass through
					if [[ -n "${line}" ]] && [[ ! "${line}" =~ ^[[:space:]]*$ ]]; then
						printf "\n%s\n" "${line}"
					fi
				fi
			done
			
			download_result=${PIPESTATUS[0]}
			
			# Clear the progress line
			printf "\r%*s\r" 100 ""
			
			if [[ ${download_result} -eq 0 ]]; then
				download_success=true
				break
			else
				if [[ ${attempt} -lt ${max_attempts} ]]; then
					log_warn "Download failed, retrying in ${delay}s..."
					sleep "${delay}"
					delay=$((delay * 2))  # Exponential backoff
				fi
			fi
			
			attempt=$((attempt + 1))
		done
		
		if ${download_success}; then
			log_success "Download completed successfully"
			return 0
		else
			log_error "Download failed after ${max_attempts} attempts"
			return 1
		fi
	else
		# For wget and curl, use the spinner as before
		log_spinner_start "Downloading..."
		if util_retry "${DUMPRX_MAX_RETRIES}" 5 "${download_cmd}" "${download_args[@]}"; then
			log_spinner_stop
			log_success "Download completed successfully"
			return 0
		else
			log_spinner_stop
			log_error "Download failed after ${DUMPRX_MAX_RETRIES} attempts"
			return 1
		fi
	fi
}

# Download from Mega.nz
function download_mega() {
	local url="$1"
	local output_dir="${2:-.}"
	local downloader="${MEGAMEDIADRIVE_DL:-}"
	
	if [[ -z "${downloader}" ]] || [[ ! -f "${downloader}" ]]; then
		log_error "Mega downloader script not found"
		return 1
	fi
	
	log_info "Downloading from Mega.nz"
	
	util_mkdir "${output_dir}" || return 1
	cd "${output_dir}" || return 1
	
	if [[ "${DUMPRX_DRY_RUN}" == "true" ]]; then
		log_info "[DRY RUN] Would download from Mega: ${url}"
		return 0
	fi
	
	log_spinner_start "Downloading from Mega.nz..."
	if bash "${downloader}" "${url}"; then
		log_spinner_stop
		log_success "Mega download completed"
		return 0
	else
		log_spinner_stop
		log_error "Mega download failed"
		return 1
	fi
}

# Download from MediaFire
function download_mediafire() {
	local url="$1"
	local output_dir="${2:-.}"
	local downloader="${MEGAMEDIADRIVE_DL:-}"
	
	if [[ -z "${downloader}" ]] || [[ ! -f "${downloader}" ]]; then
		log_error "MediaFire downloader script not found"
		return 1
	fi
	
	log_info "Downloading from MediaFire"
	
	util_mkdir "${output_dir}" || return 1
	cd "${output_dir}" || return 1
	
	if [[ "${DUMPRX_DRY_RUN}" == "true" ]]; then
		log_info "[DRY RUN] Would download from MediaFire: ${url}"
		return 0
	fi
	
	log_spinner_start "Downloading from MediaFire..."
	if bash "${downloader}" "${url}"; then
		log_spinner_stop
		log_success "MediaFire download completed"
		return 0
	else
		log_spinner_stop
		log_error "MediaFire download failed"
		return 1
	fi
}

# Download from Google Drive
function download_gdrive() {
	local url="$1"
	local output_dir="${2:-.}"
	local downloader="${MEGAMEDIADRIVE_DL:-}"
	
	if [[ -z "${downloader}" ]] || [[ ! -f "${downloader}" ]]; then
		log_error "Google Drive downloader script not found"
		return 1
	fi
	
	log_info "Downloading from Google Drive"
	
	util_mkdir "${output_dir}" || return 1
	cd "${output_dir}" || return 1
	
	if [[ "${DUMPRX_DRY_RUN}" == "true" ]]; then
		log_info "[DRY RUN] Would download from Google Drive: ${url}"
		return 0
	fi
	
	log_spinner_start "Downloading from Google Drive..."
	if bash "${downloader}" "${url}"; then
		log_spinner_stop
		log_success "Google Drive download completed"
		return 0
	else
		log_spinner_stop
		log_error "Google Drive download failed"
		return 1
	fi
}

# Download from AndroidFileHost
function download_afh() {
	local url="$1"
	local output_dir="${2:-.}"
	local downloader="${AFHDL:-}"
	
	if [[ -z "${downloader}" ]] || [[ ! -f "${downloader}" ]]; then
		log_error "AndroidFileHost downloader script not found"
		return 1
	fi
	
	log_info "Downloading from AndroidFileHost"
	
	util_mkdir "${output_dir}" || return 1
	cd "${output_dir}" || return 1
	
	if [[ "${DUMPRX_DRY_RUN}" == "true" ]]; then
		log_info "[DRY RUN] Would download from AFH: ${url}"
		return 0
	fi
	
	log_spinner_start "Downloading from AndroidFileHost..."
	if python3 "${downloader}" -l "${url}"; then
		log_spinner_stop
		log_success "AndroidFileHost download completed"
		return 0
	else
		log_spinner_stop
		log_error "AndroidFileHost download failed"
		return 1
	fi
}

# Download from WeTransfer
function download_wetransfer() {
	local url="$1"
	local output_dir="${2:-.}"
	local downloader="${TRANSFER:-}"
	
	if [[ -z "${downloader}" ]] || [[ ! -f "${downloader}" ]]; then
		log_error "WeTransfer downloader not found"
		return 1
	fi
	
	log_info "Downloading from WeTransfer"
	
	util_mkdir "${output_dir}" || return 1
	cd "${output_dir}" || return 1
	
	if [[ "${DUMPRX_DRY_RUN}" == "true" ]]; then
		log_info "[DRY RUN] Would download from WeTransfer: ${url}"
		return 0
	fi
	
	log_spinner_start "Downloading from WeTransfer..."
	if "${downloader}" "${url}"; then
		log_spinner_stop
		log_success "WeTransfer download completed"
		return 0
	else
		log_spinner_stop
		log_error "WeTransfer download failed"
		return 1
	fi
}

# Main download dispatcher
function download_file() {
	local url="$1"
	local output_dir="${2:-.}"
	local filename="${3:-}"
	
	# Normalize OneDrive URLs
	if echo "${url}" | grep -q "1drv.ms"; then
		url="${url/ms/ws}"
		log_debug "Normalized OneDrive URL: ${url}"
	fi
	
	# Detect source and download
	if echo "${url}" | grep -q "mega.nz"; then
		download_mega "${url}" "${output_dir}"
	elif echo "${url}" | grep -q "mediafire.com"; then
		download_mediafire "${url}" "${output_dir}"
	elif echo "${url}" | grep -q "drive.google.com"; then
		download_gdrive "${url}" "${output_dir}"
	elif echo "${url}" | grep -q "androidfilehost.com"; then
		download_afh "${url}" "${output_dir}"
	elif echo "${url}" | grep -q "/we.tl/"; then
		download_wetransfer "${url}" "${output_dir}"
	else
		download_direct "${url}" "${output_dir}" "${filename}"
	fi
	
	local result=$?
	
	# Sanitize downloaded filenames
	if [[ ${result} -eq 0 ]]; then
		cd "${output_dir}" || return 1
		for f in *; do
			if [[ -f "${f}" ]]; then
				if util_command_exists detox; then
					detox -r "${f}" 2>/dev/null
				fi
			fi
		done
	fi
	
	return ${result}
}

# Verify download integrity
function download_verify() {
	local file="$1"
	local checksum="${2:-}"
	local algorithm="${3:-sha256}"
	
	if [[ "${DUMPRX_VERIFY_CHECKSUMS}" != "true" ]]; then
		log_debug "Checksum verification disabled"
		return 0
	fi
	
	if [[ -z "${checksum}" ]]; then
		log_warn "No checksum provided for verification"
		return 0
	fi
	
	log_info "Verifying download integrity..."
	util_verify_checksum "${file}" "${checksum}" "${algorithm}"
}
