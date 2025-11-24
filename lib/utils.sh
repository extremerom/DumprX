#!/bin/bash

# DumprX Utilities Library
# Common utility functions used across the dumper scripts

# Source logger if not already sourced
if ! command -v log_info &> /dev/null; then
	source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"
fi

# Check if a command exists
function util_command_exists() {
	command -v "$1" &> /dev/null
}

# Verify required commands are available
function util_check_dependencies() {
	local missing_deps=()
	for cmd in "$@"; do
		if ! util_command_exists "${cmd}"; then
			missing_deps+=("${cmd}")
		fi
	done
	
	if [[ ${#missing_deps[@]} -gt 0 ]]; then
		log_error "Missing required dependencies: ${missing_deps[*]}"
		log_info "Please run setup.sh to install dependencies"
		return 1
	fi
	return 0
}

# Sanitize filename (remove special characters, spaces)
function util_sanitize_filename() {
	local filename="$1"
	# Remove or replace problematic characters
	filename="${filename//[^a-zA-Z0-9._-]/_}"
	echo "${filename}"
}

# Get file size in human-readable format
function util_human_filesize() {
	local file="$1"
	if [[ ! -f "${file}" ]]; then
		echo "N/A"
		return
	fi
	
	local size
	size=$(stat -c%s "${file}" 2>/dev/null || stat -f%z "${file}" 2>/dev/null)
	
	if [[ -z "${size}" ]]; then
		echo "N/A"
		return
	fi
	
	if [[ ${size} -lt 1024 ]]; then
		echo "${size}B"
	elif [[ ${size} -lt 1048576 ]]; then
		echo "$((size / 1024))KB"
	elif [[ ${size} -lt 1073741824 ]]; then
		echo "$((size / 1048576))MB"
	else
		echo "$((size / 1073741824))GB"
	fi
}

# Calculate file checksum
function util_checksum() {
	local file="$1"
	local algorithm="${2:-sha256}"
	
	if [[ ! -f "${file}" ]]; then
		log_error "File not found: ${file}"
		return 1
	fi
	
	case "${algorithm}" in
		md5)
			if util_command_exists md5sum; then
				md5sum "${file}" | awk '{print $1}'
			elif util_command_exists md5; then
				md5 -q "${file}"
			fi
			;;
		sha1)
			if util_command_exists sha1sum; then
				sha1sum "${file}" | awk '{print $1}'
			elif util_command_exists shasum; then
				shasum -a 1 "${file}" | awk '{print $1}'
			fi
			;;
		sha256)
			if util_command_exists sha256sum; then
				sha256sum "${file}" | awk '{print $1}'
			elif util_command_exists shasum; then
				shasum -a 256 "${file}" | awk '{print $1}'
			fi
			;;
		*)
			log_error "Unsupported checksum algorithm: ${algorithm}"
			return 1
			;;
	esac
}

# Verify file checksum
function util_verify_checksum() {
	local file="$1"
	local expected="$2"
	local algorithm="${3:-sha256}"
	
	log_debug "Verifying ${algorithm} checksum for ${file}"
	local actual
	actual=$(util_checksum "${file}" "${algorithm}")
	
	if [[ "${actual}" == "${expected}" ]]; then
		log_success "Checksum verification passed"
		return 0
	else
		log_error "Checksum verification failed"
		log_debug "Expected: ${expected}"
		log_debug "Actual: ${actual}"
		return 1
	fi
}

# Create directory with error handling
function util_mkdir() {
	local dir="$1"
	if ! mkdir -p "${dir}" 2>/dev/null; then
		log_error "Failed to create directory: ${dir}"
		return 1
	fi
	log_debug "Created directory: ${dir}"
	return 0
}

# Remove directory/file with error handling
function util_remove() {
	local path="$1"
	if [[ ! -e "${path}" ]]; then
		log_debug "Path does not exist (already removed?): ${path}"
		return 0
	fi
	
	if ! rm -rf "${path}" 2>/dev/null; then
		log_error "Failed to remove: ${path}"
		return 1
	fi
	log_debug "Removed: ${path}"
	return 0
}

# Copy with error handling
function util_copy() {
	local src="$1"
	local dst="$2"
	
	if [[ ! -e "${src}" ]]; then
		log_error "Source does not exist: ${src}"
		return 1
	fi
	
	if ! cp -a "${src}" "${dst}" 2>/dev/null; then
		log_error "Failed to copy ${src} to ${dst}"
		return 1
	fi
	log_debug "Copied ${src} to ${dst}"
	return 0
}

# Move with error handling
function util_move() {
	local src="$1"
	local dst="$2"
	
	if [[ ! -e "${src}" ]]; then
		log_error "Source does not exist: ${src}"
		return 1
	fi
	
	if ! mv -f "${src}" "${dst}" 2>/dev/null; then
		log_error "Failed to move ${src} to ${dst}"
		return 1
	fi
	log_debug "Moved ${src} to ${dst}"
	return 0
}

# Get absolute path
function util_realpath() {
	local path="$1"
	if util_command_exists realpath; then
		realpath "${path}" 2>/dev/null
	else
		# Fallback for systems without realpath
		python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "${path}" 2>/dev/null
	fi
}

# Check if path has spaces
function util_has_spaces() {
	local path="$1"
	if echo "${path}" | grep -q " "; then
		return 0
	fi
	return 1
}

# Wait with timeout
function util_wait_for() {
	local timeout=$1
	local interval="${2:-1}"
	local message="${3:-Waiting}"
	
	local elapsed=0
	while [[ ${elapsed} -lt ${timeout} ]]; do
		sleep "${interval}"
		elapsed=$((elapsed + interval))
	done
}

# Retry command with exponential backoff
function util_retry() {
	local max_attempts="${1:-3}"
	local delay="${2:-1}"
	shift 2
	local command=("$@")
	
	local attempt=1
	while [[ ${attempt} -le ${max_attempts} ]]; do
		log_debug "Attempt ${attempt}/${max_attempts}: ${command[*]}"
		if "${command[@]}"; then
			return 0
		fi
		
		if [[ ${attempt} -lt ${max_attempts} ]]; then
			log_warn "Command failed, retrying in ${delay}s..."
			sleep "${delay}"
			delay=$((delay * 2))  # Exponential backoff
		fi
		attempt=$((attempt + 1))
	done
	
	log_error "Command failed after ${max_attempts} attempts"
	return 1
}

# Check if running as root
function util_is_root() {
	if [[ "${EUID}" -eq 0 ]]; then
		return 0
	fi
	return 1
}

# Get free disk space in MB
function util_free_space() {
	local path="${1:-.}"
	df -m "${path}" | tail -1 | awk '{print $4}'
}

# Check if enough disk space is available
function util_check_disk_space() {
	local required_mb=$1
	local path="${2:-.}"
	
	local available
	available=$(util_free_space "${path}")
	
	if [[ ${available} -lt ${required_mb} ]]; then
		log_error "Insufficient disk space. Required: ${required_mb}MB, Available: ${available}MB"
		return 1
	fi
	
	log_debug "Disk space check passed. Required: ${required_mb}MB, Available: ${available}MB"
	return 0
}

# Find files by pattern
function util_find_files() {
	local base_dir="$1"
	local pattern="$2"
	local max_depth="${3:-1}"
	
	find "${base_dir}" -maxdepth "${max_depth}" -type f -name "${pattern}" 2>/dev/null
}

# Count files matching pattern
function util_count_files() {
	local base_dir="$1"
	local pattern="$2"
	local max_depth="${3:-1}"
	
	util_find_files "${base_dir}" "${pattern}" "${max_depth}" | wc -l
}

# Clean temporary files
function util_cleanup_temp() {
	local temp_dir="$1"
	if [[ -n "${temp_dir}" ]] && [[ -d "${temp_dir}" ]]; then
		log_debug "Cleaning up temporary directory: ${temp_dir}"
		util_remove "${temp_dir}"
	fi
}

# Trap cleanup on exit
function util_trap_cleanup() {
	local cleanup_func="$1"
	trap ''"${cleanup_func}"'' EXIT INT TERM
}

# Generate unique temporary directory
function util_make_temp_dir() {
	local base_dir="${1:-/tmp}"
	local prefix="${2:-dumprx}"
	
	local temp_dir
	temp_dir=$(mktemp -d "${base_dir}/${prefix}.XXXXXX" 2>/dev/null)
	
	if [[ -z "${temp_dir}" ]] || [[ ! -d "${temp_dir}" ]]; then
		log_error "Failed to create temporary directory"
		return 1
	fi
	
	echo "${temp_dir}"
	return 0
}

# Parse INI-style configuration file
function util_parse_config() {
	local config_file="$1"
	local section="${2:-}"
	
	if [[ ! -f "${config_file}" ]]; then
		log_debug "Config file not found: ${config_file}"
		return 1
	fi
	
	if [[ -n "${section}" ]]; then
		# Parse specific section
		sed -n "/^\[${section}\]/,/^\[/p" "${config_file}" | grep -v "^\[" | grep -v "^#" | grep -v "^$"
	else
		# Parse all
		grep -v "^#" "${config_file}" | grep -v "^$"
	fi
}

# Detect OS type
function util_detect_os() {
	if [[ -f /etc/os-release ]]; then
		# Safely parse the ID field without sourcing the file
		local os_id
		os_id=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"' | tr -d "'")
		if [[ -n "${os_id}" ]]; then
			echo "${os_id}"
		else
			echo "linux"
		fi
	elif [[ "${OSTYPE}" == "darwin"* ]]; then
		echo "macos"
	elif [[ "${OSTYPE}" == "linux-gnu"* ]]; then
		echo "linux"
	else
		echo "unknown"
	fi
}

# Check if file is compressed
function util_is_compressed() {
	local file="$1"
	local extension="${file##*.}"
	
	case "${extension,,}" in
		zip|rar|7z|tar|gz|tgz|bz2|xz|lz|lzma|br|zst)
			return 0
			;;
		*)
			return 1
			;;
	esac
}

# Validate URL
function util_is_url() {
	local url="$1"
	if echo "${url}" | grep -qE '^(https?|ftp)://'; then
		return 0
	fi
	return 1
}

# Validate email
function util_is_email() {
	local email="$1"
	if echo "${email}" | grep -qE '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'; then
		return 0
	fi
	return 1
}

# Get script directory
function util_script_dir() {
	local source="${BASH_SOURCE[0]}"
	while [ -h "$source" ]; do
		local dir
		dir="$(cd -P "$(dirname "$source")" && pwd)"
		source="$(readlink "$source")"
		[[ $source != /* ]] && source="$dir/$source"
	done
	cd -P "$(dirname "$source")" && pwd
}

# Print colored text
function util_print_color() {
	local color="$1"
	shift
	local message="$*"
	
	if [[ "${DUMPRX_LOG_COLORS}" == "true" ]]; then
		case "${color,,}" in
			red)     echo -e "${LOG_COLOR_RED}${message}${LOG_COLOR_RESET}" ;;
			green)   echo -e "${LOG_COLOR_GREEN}${message}${LOG_COLOR_RESET}" ;;
			yellow)  echo -e "${LOG_COLOR_YELLOW}${message}${LOG_COLOR_RESET}" ;;
			blue)    echo -e "${LOG_COLOR_BLUE}${message}${LOG_COLOR_RESET}" ;;
			magenta) echo -e "${LOG_COLOR_MAGENTA}${message}${LOG_COLOR_RESET}" ;;
			cyan)    echo -e "${LOG_COLOR_CYAN}${message}${LOG_COLOR_RESET}" ;;
			*)       echo "${message}" ;;
		esac
	else
		echo "${message}"
	fi
}
