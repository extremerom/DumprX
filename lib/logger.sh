#!/bin/bash

# DumprX Logging Library
# Provides comprehensive logging functionality with multiple levels,
# colored output, timestamps, and file logging support

# Initialize logging variables
DUMPRX_LOG_LEVEL="${DUMPRX_LOG_LEVEL:-INFO}"
DUMPRX_LOG_FILE="${DUMPRX_LOG_FILE:-}"
DUMPRX_LOG_COLORS="${DUMPRX_LOG_COLORS:-true}"
DUMPRX_LOG_TIMESTAMP="${DUMPRX_LOG_TIMESTAMP:-true}"
DUMPRX_QUIET_MODE="${DUMPRX_QUIET_MODE:-false}"
DUMPRX_VERBOSE_MODE="${DUMPRX_VERBOSE_MODE:-false}"

# Color codes
readonly LOG_COLOR_RESET='\033[0m'
readonly LOG_COLOR_RED='\033[0;31m'
readonly LOG_COLOR_GREEN='\033[0;32m'
readonly LOG_COLOR_YELLOW='\033[0;33m'
readonly LOG_COLOR_BLUE='\033[0;34m'
readonly LOG_COLOR_MAGENTA='\033[0;35m'
readonly LOG_COLOR_CYAN='\033[0;36m'
readonly LOG_COLOR_WHITE='\033[0;37m'
readonly LOG_COLOR_BOLD='\033[1m'
readonly LOG_COLOR_DIM='\033[2m'

# Log level values (higher = more severe)
readonly LOG_LEVEL_DEBUG=0
readonly LOG_LEVEL_INFO=1
readonly LOG_LEVEL_SUCCESS=2
readonly LOG_LEVEL_WARN=3
readonly LOG_LEVEL_ERROR=4
readonly LOG_LEVEL_FATAL=5

# Current log level value
_LOG_LEVEL_VALUE=${LOG_LEVEL_INFO}

# Set log level from string
function log_set_level() {
	case "${1^^}" in
		DEBUG)   _LOG_LEVEL_VALUE=${LOG_LEVEL_DEBUG} ;;
		INFO)    _LOG_LEVEL_VALUE=${LOG_LEVEL_INFO} ;;
		SUCCESS) _LOG_LEVEL_VALUE=${LOG_LEVEL_SUCCESS} ;;
		WARN)    _LOG_LEVEL_VALUE=${LOG_LEVEL_WARN} ;;
		ERROR)   _LOG_LEVEL_VALUE=${LOG_LEVEL_ERROR} ;;
		FATAL)   _LOG_LEVEL_VALUE=${LOG_LEVEL_FATAL} ;;
		*)       _LOG_LEVEL_VALUE=${LOG_LEVEL_INFO} ;;
	esac
	DUMPRX_LOG_LEVEL="${1^^}"
}

# Initialize log file
function log_init() {
	if [[ -n "${DUMPRX_LOG_FILE}" ]]; then
		local log_dir
		log_dir=$(dirname "${DUMPRX_LOG_FILE}")
		mkdir -p "${log_dir}" 2>/dev/null
		: > "${DUMPRX_LOG_FILE}" 2>/dev/null || {
			echo "Warning: Cannot write to log file: ${DUMPRX_LOG_FILE}" >&2
			DUMPRX_LOG_FILE=""
		}
	fi
	
	# Set log level from environment
	log_set_level "${DUMPRX_LOG_LEVEL}"
	
	# Adjust for verbose/quiet modes
	if [[ "${DUMPRX_VERBOSE_MODE}" == "true" ]]; then
		log_set_level "DEBUG"
	fi
}

# Get timestamp
function _log_timestamp() {
	if [[ "${DUMPRX_LOG_TIMESTAMP}" == "true" ]]; then
		date '+%Y-%m-%d %H:%M:%S'
	fi
}

# Core logging function
function _log() {
	local level=$1
	local level_name=$2
	local color=$3
	local symbol=$4
	shift 4
	local message="$*"
	
	# Check log level
	if [[ ${level} -lt ${_LOG_LEVEL_VALUE} ]]; then
		return 0
	fi
	
	# Skip console output in quiet mode (except errors)
	if [[ "${DUMPRX_QUIET_MODE}" == "true" ]] && [[ ${level} -lt ${LOG_LEVEL_ERROR} ]]; then
		# Still write to log file if configured
		if [[ -n "${DUMPRX_LOG_FILE}" ]]; then
			local timestamp
			timestamp=$(_log_timestamp)
			echo "[${timestamp}] [${level_name}] ${message}" >> "${DUMPRX_LOG_FILE}"
		fi
		return 0
	fi
	
	# Build output message
	local output=""
	local file_output=""
	
	# Timestamp
	if [[ "${DUMPRX_LOG_TIMESTAMP}" == "true" ]]; then
		local timestamp
		timestamp=$(_log_timestamp)
		if [[ "${DUMPRX_LOG_COLORS}" == "true" ]]; then
			output="${LOG_COLOR_DIM}[${timestamp}]${LOG_COLOR_RESET} "
		else
			output="[${timestamp}] "
		fi
		file_output="[${timestamp}] "
	fi
	
	# Level indicator
	if [[ "${DUMPRX_LOG_COLORS}" == "true" ]]; then
		output="${output}${color}${symbol} ${level_name}:${LOG_COLOR_RESET} "
	else
		output="${output}${symbol} ${level_name}: "
	fi
	file_output="${file_output}[${level_name}] "
	
	# Message
	if [[ "${DUMPRX_LOG_COLORS}" == "true" ]] && [[ ${level} -ge ${LOG_LEVEL_WARN} ]]; then
		output="${output}${color}${message}${LOG_COLOR_RESET}"
	else
		output="${output}${message}"
	fi
	file_output="${file_output}${message}"
	
	# Output to console
	echo -e "${output}"
	
	# Output to file
	if [[ -n "${DUMPRX_LOG_FILE}" ]]; then
		echo "${file_output}" >> "${DUMPRX_LOG_FILE}"
	fi
}

# Public logging functions
function log_debug() {
	_log ${LOG_LEVEL_DEBUG} "DEBUG" "${LOG_COLOR_CYAN}" "🔍" "$@"
}

function log_info() {
	_log ${LOG_LEVEL_INFO} "INFO" "${LOG_COLOR_BLUE}" "ℹ️" "$@"
}

function log_success() {
	_log ${LOG_LEVEL_SUCCESS} "SUCCESS" "${LOG_COLOR_GREEN}" "✓" "$@"
}

function log_warn() {
	_log ${LOG_LEVEL_WARN} "WARN" "${LOG_COLOR_YELLOW}" "⚠️" "$@"
}

function log_error() {
	_log ${LOG_LEVEL_ERROR} "ERROR" "${LOG_COLOR_RED}" "✗" "$@"
}

function log_fatal() {
	_log ${LOG_LEVEL_FATAL} "FATAL" "${LOG_COLOR_RED}${LOG_COLOR_BOLD}" "💀" "$@"
}

# Step logging for progress tracking
DUMPRX_CURRENT_STEP=0
DUMPRX_TOTAL_STEPS=0

function log_step() {
	((DUMPRX_CURRENT_STEP++))
	local step_info=""
	if [[ ${DUMPRX_TOTAL_STEPS} -gt 0 ]]; then
		step_info=" [${DUMPRX_CURRENT_STEP}/${DUMPRX_TOTAL_STEPS}]"
	else
		step_info=" [${DUMPRX_CURRENT_STEP}]"
	fi
	
	if [[ "${DUMPRX_LOG_COLORS}" == "true" ]]; then
		echo -e "${LOG_COLOR_MAGENTA}${LOG_COLOR_BOLD}▶${step_info}${LOG_COLOR_RESET} ${LOG_COLOR_BOLD}$*${LOG_COLOR_RESET}"
	else
		echo "▶${step_info} $*"
	fi
	
	if [[ -n "${DUMPRX_LOG_FILE}" ]]; then
		echo "[STEP${step_info}] $*" >> "${DUMPRX_LOG_FILE}"
	fi
}

function log_set_steps() {
	DUMPRX_TOTAL_STEPS=$1
	DUMPRX_CURRENT_STEP=0
}

# Section headers
function log_header() {
	local header="$*"
	local line
	line=$(printf '=%.0s' $(seq 1 ${#header}))
	
	if [[ "${DUMPRX_LOG_COLORS}" == "true" ]]; then
		echo -e "\n${LOG_COLOR_BOLD}${LOG_COLOR_CYAN}${line}${LOG_COLOR_RESET}"
		echo -e "${LOG_COLOR_BOLD}${LOG_COLOR_CYAN}${header}${LOG_COLOR_RESET}"
		echo -e "${LOG_COLOR_BOLD}${LOG_COLOR_CYAN}${line}${LOG_COLOR_RESET}\n"
	else
		echo -e "\n${line}"
		echo "${header}"
		echo -e "${line}\n"
	fi
	
	if [[ -n "${DUMPRX_LOG_FILE}" ]]; then
		{
			echo ""
			echo "${line}"
			echo "${header}"
			echo "${line}"
			echo ""
		} >> "${DUMPRX_LOG_FILE}"
	fi
}

# Progress bar
function log_progress() {
	local current=$1
	local total=$2
	local message="${3:-}"
	
	local percent=$((current * 100 / total))
	local filled=$((percent / 2))
	local empty=$((50 - filled))
	
	local bar=""
	bar=$(printf '█%.0s' $(seq 1 ${filled}))
	bar="${bar}$(printf '░%.0s' $(seq 1 ${empty}))"
	
	if [[ "${DUMPRX_LOG_COLORS}" == "true" ]]; then
		printf "\r${LOG_COLOR_CYAN}%3d%%${LOG_COLOR_RESET} [${LOG_COLOR_GREEN}%s${LOG_COLOR_RESET}] %s" "${percent}" "${bar}" "${message}"
	else
		printf "\r%3d%% [%s] %s" "${percent}" "${bar}" "${message}"
	fi
	
	if [[ ${current} -eq ${total} ]]; then
		echo ""
	fi
}

# Spinner for long-running operations
DUMPRX_SPINNER_PID=""
DUMPRX_SPINNER_MESSAGE=""

function _log_spinner() {
	local spinner=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
	local i=0
	while true; do
		if [[ "${DUMPRX_LOG_COLORS}" == "true" ]]; then
			printf "\r${LOG_COLOR_CYAN}%s${LOG_COLOR_RESET} %s" "${spinner[$i]}" "${DUMPRX_SPINNER_MESSAGE}"
		else
			printf "\r%s %s" "${spinner[$i]}" "${DUMPRX_SPINNER_MESSAGE}"
		fi
		i=$(( (i + 1) % ${#spinner[@]} ))
		sleep 0.1
	done
}

function log_spinner_start() {
	DUMPRX_SPINNER_MESSAGE="$*"
	_log_spinner &
	DUMPRX_SPINNER_PID=$!
	# Disable job control messages
	disown 2>/dev/null
}

function log_spinner_stop() {
	if [[ -n "${DUMPRX_SPINNER_PID}" ]]; then
		kill "${DUMPRX_SPINNER_PID}" 2>/dev/null
		wait "${DUMPRX_SPINNER_PID}" 2>/dev/null
		DUMPRX_SPINNER_PID=""
		printf "\r%*s\r" 80 ""  # Clear line
	fi
}

# Summary report
declare -a DUMPRX_SUMMARY_ITEMS=()

function log_summary_add() {
	local label="$1"
	local value="$2"
	DUMPRX_SUMMARY_ITEMS+=("${label}|${value}")
}

function log_summary_print() {
	log_header "Summary Report"
	
	local max_label_length=0
	for item in "${DUMPRX_SUMMARY_ITEMS[@]}"; do
		local label="${item%%|*}"
		if [[ ${#label} -gt ${max_label_length} ]]; then
			max_label_length=${#label}
		fi
	done
	
	for item in "${DUMPRX_SUMMARY_ITEMS[@]}"; do
		local label="${item%%|*}"
		local value="${item#*|}"
		printf "  %-${max_label_length}s : %s\n" "${label}" "${value}"
		
		if [[ -n "${DUMPRX_LOG_FILE}" ]]; then
			printf "  %-${max_label_length}s : %s\n" "${label}" "${value}" >> "${DUMPRX_LOG_FILE}"
		fi
	done
	
	echo ""
	DUMPRX_SUMMARY_ITEMS=()
}

# Initialize on source
log_init
