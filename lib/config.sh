#!/bin/bash

# DumprX Configuration Library
# Handles configuration file loading and management

# Source dependencies
if ! command -v log_info &> /dev/null; then
	source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"
fi

if ! command -v util_parse_config &> /dev/null; then
	source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"
fi

# Default configuration values
DUMPRX_CONFIG_FILE="${DUMPRX_CONFIG_FILE:-.dumprx.conf}"
DUMPRX_DRY_RUN="${DUMPRX_DRY_RUN:-false}"
DUMPRX_VERIFY_CHECKSUMS="${DUMPRX_VERIFY_CHECKSUMS:-false}"
DUMPRX_KEEP_TEMP="${DUMPRX_KEEP_TEMP:-false}"
DUMPRX_MAX_RETRIES="${DUMPRX_MAX_RETRIES:-3}"
DUMPRX_DOWNLOAD_TIMEOUT="${DUMPRX_DOWNLOAD_TIMEOUT:-3600}"
DUMPRX_ENABLE_SUMMARY="${DUMPRX_ENABLE_SUMMARY:-true}"

# Load configuration from file
function config_load() {
	local config_file="${1:-${DUMPRX_CONFIG_FILE}}"
	
	# Check global config locations
	local config_paths=(
		"${config_file}"
		"${HOME}/.dumprx.conf"
		"${HOME}/.config/dumprx/config"
		"/etc/dumprx/config"
	)
	
	local found_config=""
	for path in "${config_paths[@]}"; do
		if [[ -f "${path}" ]]; then
			found_config="${path}"
			break
		fi
	done
	
	if [[ -z "${found_config}" ]]; then
		log_debug "No configuration file found, using defaults"
		return 0
	fi
	
	log_debug "Loading configuration from: ${found_config}"
	
	# Parse and load configuration
	while IFS='=' read -r key value; do
		# Skip empty lines and comments
		[[ -z "${key}" ]] || [[ "${key}" =~ ^[[:space:]]*# ]] && continue
		
		# Trim whitespace
		key=$(echo "${key}" | xargs)
		value=$(echo "${value}" | xargs)
		
		# Remove quotes from value
		value="${value%\"}"
		value="${value#\"}"
		value="${value%\'}"
		value="${value#\'}"
		
		# Set environment variable
		case "${key}" in
			log_level)
				export DUMPRX_LOG_LEVEL="${value}"
				log_set_level "${value}"
				;;
			log_file)
				export DUMPRX_LOG_FILE="${value}"
				;;
			log_colors)
				export DUMPRX_LOG_COLORS="${value}"
				;;
			log_timestamp)
				export DUMPRX_LOG_TIMESTAMP="${value}"
				;;
			quiet_mode)
				export DUMPRX_QUIET_MODE="${value}"
				;;
			verbose_mode)
				export DUMPRX_VERBOSE_MODE="${value}"
				;;
			dry_run)
				export DUMPRX_DRY_RUN="${value}"
				;;
			verify_checksums)
				export DUMPRX_VERIFY_CHECKSUMS="${value}"
				;;
			keep_temp)
				export DUMPRX_KEEP_TEMP="${value}"
				;;
			max_retries)
				export DUMPRX_MAX_RETRIES="${value}"
				;;
			download_timeout)
				export DUMPRX_DOWNLOAD_TIMEOUT="${value}"
				;;
			enable_summary)
				export DUMPRX_ENABLE_SUMMARY="${value}"
				;;
			*)
				# Store custom configuration
				export "DUMPRX_CUSTOM_${key}=${value}"
				;;
		esac
	done < <(grep -v "^\[" "${found_config}" | grep -v "^#" | grep "=")
	
	log_debug "Configuration loaded successfully"
	return 0
}

# Save current configuration to file
function config_save() {
	local config_file="${1:-${DUMPRX_CONFIG_FILE}}"
	
	log_info "Saving configuration to: ${config_file}"
	
	cat > "${config_file}" << EOF
# DumprX Configuration File
# Generated on $(date)

# Logging settings
log_level = ${DUMPRX_LOG_LEVEL}
log_file = ${DUMPRX_LOG_FILE}
log_colors = ${DUMPRX_LOG_COLORS}
log_timestamp = ${DUMPRX_LOG_TIMESTAMP}
quiet_mode = ${DUMPRX_QUIET_MODE}
verbose_mode = ${DUMPRX_VERBOSE_MODE}

# Operation settings
dry_run = ${DUMPRX_DRY_RUN}
verify_checksums = ${DUMPRX_VERIFY_CHECKSUMS}
keep_temp = ${DUMPRX_KEEP_TEMP}
max_retries = ${DUMPRX_MAX_RETRIES}
download_timeout = ${DUMPRX_DOWNLOAD_TIMEOUT}
enable_summary = ${DUMPRX_ENABLE_SUMMARY}
EOF
	
	log_success "Configuration saved successfully"
	return 0
}

# Generate example configuration file
function config_generate_example() {
	local config_file="${1:-.dumprx.conf.example}"
	
	cat > "${config_file}" << 'EOF'
# DumprX Configuration File Example
# Copy this file to .dumprx.conf and modify as needed

# ============================================================================
# LOGGING SETTINGS
# ============================================================================

# Log level: DEBUG, INFO, SUCCESS, WARN, ERROR, FATAL
# Default: INFO
log_level = INFO

# Log file path (leave empty to disable file logging)
# Default: (empty)
log_file = 

# Enable colored output
# Default: true
log_colors = true

# Enable timestamps in log messages
# Default: true
log_timestamp = true

# Quiet mode (only show errors)
# Default: false
quiet_mode = false

# Verbose mode (show debug messages)
# Default: false
verbose_mode = false

# ============================================================================
# OPERATION SETTINGS
# ============================================================================

# Dry run mode (don't actually perform operations)
# Default: false
dry_run = false

# Verify checksums for downloads
# Default: false
verify_checksums = false

# Keep temporary files after extraction
# Default: false
keep_temp = false

# Maximum number of retries for failed operations
# Default: 3
max_retries = 3

# Download timeout in seconds
# Default: 3600 (1 hour)
download_timeout = 3600

# Enable summary report at the end
# Default: true
enable_summary = true

# ============================================================================
# CUSTOM SETTINGS
# ============================================================================
# You can add custom settings here. They will be available as:
# DUMPRX_CUSTOM_<key_name>

# Examples:
# custom_output_dir = /path/to/output
# custom_temp_dir = /path/to/temp
EOF
	
	log_success "Example configuration file generated: ${config_file}"
	return 0
}

# Get configuration value
function config_get() {
	local key="$1"
	local default="${2:-}"
	
	local var_name="DUMPRX_${key}"
	local value="${!var_name}"
	
	if [[ -z "${value}" ]]; then
		echo "${default}"
	else
		echo "${value}"
	fi
}

# Set configuration value
function config_set() {
	local key="$1"
	local value="$2"
	
	local var_name="DUMPRX_${key}"
	export "${var_name}=${value}"
}

# Show current configuration
function config_show() {
	log_header "Current Configuration"
	
	echo "Logging Settings:"
	echo "  Log Level: ${DUMPRX_LOG_LEVEL}"
	echo "  Log File: ${DUMPRX_LOG_FILE:-<not set>}"
	echo "  Log Colors: ${DUMPRX_LOG_COLORS}"
	echo "  Log Timestamp: ${DUMPRX_LOG_TIMESTAMP}"
	echo "  Quiet Mode: ${DUMPRX_QUIET_MODE}"
	echo "  Verbose Mode: ${DUMPRX_VERBOSE_MODE}"
	echo ""
	echo "Operation Settings:"
	echo "  Dry Run: ${DUMPRX_DRY_RUN}"
	echo "  Verify Checksums: ${DUMPRX_VERIFY_CHECKSUMS}"
	echo "  Keep Temp Files: ${DUMPRX_KEEP_TEMP}"
	echo "  Max Retries: ${DUMPRX_MAX_RETRIES}"
	echo "  Download Timeout: ${DUMPRX_DOWNLOAD_TIMEOUT}s"
	echo "  Enable Summary: ${DUMPRX_ENABLE_SUMMARY}"
	echo ""
}
