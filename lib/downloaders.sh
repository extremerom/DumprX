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
