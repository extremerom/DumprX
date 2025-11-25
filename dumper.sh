#!/bin/bash

# DumprX - Android Firmware Dumper (Refactored)
# Based on Phoenix Firmware Dumper with improvements and new logging system

# Set Base Project Directory (must be done before sourcing libraries)
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

# Source libraries
source "${PROJECT_DIR}/lib/logger.sh"
source "${PROJECT_DIR}/lib/utils.sh"
source "${PROJECT_DIR}/lib/config.sh"
source "${PROJECT_DIR}/lib/downloaders.sh"

# Clear Screen
tput reset 2>/dev/null || clear

# Initialize logging with default log file
export DUMPRX_LOG_FILE="${PROJECT_DIR}/dumprx.log"
export DUMPRX_LOG_TIMESTAMP=true
export DUMPRX_LOG_COLORS=true

# Load configuration if available
config_load 2>/dev/null

# Re-initialize logging after config load
log_init

# Unset variables that will be set during execution
unset INPUTDIR UTILSDIR OUTDIR TMPDIR FILEPATH FILE EXTENSION UNZIP_DIR ArcPath \
	GITHUB_TOKEN GIT_ORG TG_TOKEN CHAT_ID

# Resize Terminal Window To At least 30x90 For Better View
printf "\033[8;30;90t" || true

# Banner
function __bannerTop() {
	echo -e \
	"${LOG_COLOR_GREEN}
	██████╗░██╗░░░██╗███╗░░░███╗██████╗░██████╗░██╗░░██╗
	██╔══██╗██║░░░██║████╗░████║██╔══██╗██╔══██╗╚██╗██╔╝
	██║░░██║██║░░░██║██╔████╔██║██████╔╝██████╔╝░╚███╔╝░
	██║░░██║██║░░░██║██║╚██╔╝██║██╔═══╝░██╔══██╗░██╔██╗░
	██████╔╝╚██████╔╝██║░╚═╝░██║██║░░░░░██║░░██║██╔╝╚██╗
	╚═════╝░░╚═════╝░╚═╝░░░░░╚═╝╚═╝░░░░░╚═╝░░╚═╝╚═╝░░╚═╝
	${LOG_COLOR_RESET}"
}

# Usage/Help
function _usage() {
	echo ""
	log_info "Usage: ${0} <Firmware File/Extracted Folder -OR- Supported Website Link>"
	echo ""
	echo "  Firmware File: The .zip/.rar/.7z/.tar/.bin/.ozip/.kdz etc. file"
	echo ""
	echo "  Supported Websites:"
	echo "    1. Directly Accessible Download Link From Any Website"
	echo "    2. Filehosters like - mega.nz | mediafire | gdrive | onedrive | androidfilehost"
	echo "    Note: Must Wrap Website Link Inside Single-quotes ('')"
	echo ""
	echo "  Supported File Formats:"
	echo "    *.zip | *.rar | *.7z | *.tar | *.tar.gz | *.tgz | *.tar.md5"
	echo "    *.ozip | *.ofp | *.ops | *.kdz | ruu_*exe"
	echo "    system.new.dat | system.new.dat.br | system.new.dat.xz"
	echo "    system.new.img | system.img | system-sign.img | UPDATE.APP"
	echo "    *.emmc.img | *.img.ext4 | system.bin | system-p | payload.bin"
	echo "    *.nb0 | .*chunk* | *.pac | *super*.img | *system*.sin"
	echo ""
	echo "  Options:"
	echo "    --verbose, -v     Enable verbose (debug) logging"
	echo "    --quiet, -q       Quiet mode (only errors)"
	echo "    --dry-run         Don't actually perform operations"
	echo "    --no-colors       Disable colored output"
	echo "    --config FILE     Use specific configuration file"
	echo "    --help, -h        Show this help message"
	echo ""
}

# Welcome Banner
__bannerTop

# Parse command line arguments
FIRMWARE_INPUT=""
while [[ $# -gt 0 ]]; do
	case "$1" in
		--verbose|-v)
			export DUMPRX_VERBOSE_MODE=true
			log_set_level "DEBUG"
			shift
			;;
		--quiet|-q)
			export DUMPRX_QUIET_MODE=true
			shift
			;;
		--dry-run)
			export DUMPRX_DRY_RUN=true
			log_info "DRY RUN mode enabled - no actual operations will be performed"
			shift
			;;
		--no-colors)
			export DUMPRX_LOG_COLORS=false
			shift
			;;
		--config)
			config_load "$2"
			shift 2
			;;
		--help|-h)
			_usage
			exit 0
			;;
		*)
			if [[ -z "${FIRMWARE_INPUT}" ]]; then
				FIRMWARE_INPUT="$1"
			else
				log_error "Multiple firmware inputs detected. Please provide only one."
				_usage
				exit 1
			fi
			shift
			;;
	esac
done

# Function Input Check
if [[ -z "${FIRMWARE_INPUT}" ]]; then
	log_error "No input provided."
	_usage
	exit 1
fi

log_header "DumprX - Android Firmware Extraction Tool"

# Validate Project Directory
if util_has_spaces "${PROJECT_DIR}"; then
	log_fatal "Project directory path contains spaces. Please move the script to a proper UNIX-formatted folder."
	exit 1
fi

log_debug "Project directory: ${PROJECT_DIR}"

# Sanitize And Generate Folders
log_step "Setting up directories"
INPUTDIR="${PROJECT_DIR}/input"		# Firmware Download/Preload Directory
UTILSDIR="${PROJECT_DIR}/utils"		# Contains Supportive Programs
OUTDIR="${PROJECT_DIR}/out"			# Contains Final Extracted Files
TMPDIR="${OUTDIR}/tmp"				# Temporary Working Directory

util_remove "${TMPDIR}"
util_mkdir "${OUTDIR}" || exit 1
util_mkdir "${TMPDIR}" || exit 1

log_debug "Input directory: ${INPUTDIR}"
log_debug "Utils directory: ${UTILSDIR}"
log_debug "Output directory: ${OUTDIR}"
log_debug "Temp directory: ${TMPDIR}"

# Clone/Update External Tools
log_step "Checking external tools"
EXTERNAL_TOOLS=(
	bkerler/oppo_ozip_decrypt
	bkerler/oppo_decrypt
	marin-m/vmlinux-to-elf
	ShivamKumarJha/android_tools
	HemanthJabalpuri/pacextractor
)

for tool_slug in "${EXTERNAL_TOOLS[@]}"; do
	tool_name="${tool_slug#*/}"
	tool_path="${UTILSDIR}/${tool_name}"
	
	if [[ ! -d "${tool_path}" ]]; then
		log_info "Cloning ${tool_name}..."
		if [[ "${DUMPRX_DRY_RUN}" != "true" ]]; then
			git clone -q "https://github.com/${tool_slug}.git" "${tool_path}" 2>/dev/null || log_warn "Failed to clone ${tool_name}"
		fi
	else
		log_debug "Tool ${tool_name} already exists"
		if [[ "${DUMPRX_DRY_RUN}" != "true" ]]; then
			git -C "${tool_path}" pull -q 2>/dev/null || log_debug "Could not update ${tool_name}"
		fi
	fi
done

log_success "External tools ready"

## See README.md File For Program Credits
# Set Utility Program Alias
SDAT2IMG="${UTILSDIR}"/sdat2img.py
SIMG2IMG="${UTILSDIR}"/bin/simg2img
PACKSPARSEIMG="${UTILSDIR}"/bin/packsparseimg
UNSIN="${UTILSDIR}"/unsin
PAYLOAD_EXTRACTOR="${UTILSDIR}"/bin/payload-dumper-go
DTC="${UTILSDIR}"/dtc
VMLINUX2ELF="${UTILSDIR}"/vmlinux-to-elf/vmlinux-to-elf
KALLSYMS_FINDER="${UTILSDIR}"/vmlinux-to-elf/kallsyms-finder
OZIPDECRYPT="${UTILSDIR}"/oppo_ozip_decrypt/ozipdecrypt.py
OFP_QC_DECRYPT="${UTILSDIR}"/oppo_decrypt/ofp_qc_decrypt.py
OFP_MTK_DECRYPT="${UTILSDIR}"/oppo_decrypt/ofp_mtk_decrypt.py
OPSDECRYPT="${UTILSDIR}"/oppo_decrypt/opscrypto.py
LPUNPACK="${UTILSDIR}"/lpunpack
SPLITUAPP="${UTILSDIR}"/splituapp.py
PACEXTRACTOR="${UTILSDIR}"/pacextractor/python/pacExtractor.py
NB0_EXTRACT="${UTILSDIR}"/nb0-extract
KDZ_EXTRACT="${UTILSDIR}"/kdztools/unkdz.py
DZ_EXTRACT="${UTILSDIR}"/kdztools/undz.py
RUUDECRYPT="${UTILSDIR}"/RUU_Decrypt_Tool
EXTRACT_IKCONFIG="${UTILSDIR}"/extract-ikconfig
UNPACKBOOT="${UTILSDIR}"/unpackboot.sh
AML_EXTRACT="${UTILSDIR}"/aml-upgrade-package-extract
AFPTOOL_EXTRACT="${UTILSDIR}"/bin/afptool
RK_EXTRACT="${UTILSDIR}"/bin/rkImageMaker
TRANSFER="${UTILSDIR}"/bin/transfer

if ! command -v 7zz > /dev/null 2>&1; then
	BIN_7ZZ="${UTILSDIR}"/bin/7zz
else
	BIN_7ZZ=7zz
fi

if ! command -v uvx > /dev/null 2>&1; then
	export PATH="${HOME}/.local/bin:${PATH}"
fi

# Set Names of Downloader Utility Programs
MEGAMEDIADRIVE_DL="${UTILSDIR}"/downloaders/mega-media-drive_dl.sh
AFHDL="${UTILSDIR}"/downloaders/afh_dl.py

# EROFS
FSCK_EROFS=${UTILSDIR}/bin/fsck.erofs

# Partition List That Are Currently Supported
PARTITIONS="system system_ext system_other systemex vendor cust odm oem factory product xrom modem dtbo dtb boot vendor_boot recovery tz oppo_product preload_common opproduct reserve india my_preload my_odm my_stock my_operator my_country my_product my_company my_engineering my_heytap my_custom my_manifest my_carrier my_region my_bigball my_version special_preload system_dlkm vendor_dlkm odm_dlkm init_boot vendor_kernel_boot odmko socko nt_log mi_ext hw_product product_h preas preavs optics omr prism persist"
EXT4PARTITIONS="system vendor cust odm oem factory product xrom systemex oppo_product preload_common hw_product product_h preas preavs optics omr prism persist"
OTHERPARTITIONS="tz.mbn:tz tz.img:tz modem.img:modem NON-HLOS:modem boot-verified.img:boot recovery-verified.img:recovery dtbo-verified.img:dtbo"

# NOTE: Handle input from ${PROJECT_DIR}/input
if echo "${FIRMWARE_INPUT}" | grep -q "${PROJECT_DIR}/input" && [[ $(find "${INPUTDIR}" -maxdepth 1 -type f -size +10M -print | wc -l) -gt 1 ]]; then
	FILEPATH=$(util_realpath "${FIRMWARE_INPUT}")
	log_info "Copying files to temporary directory"
	util_copy "${FILEPATH}"/* "${TMPDIR}/" || exit 1
	unset FILEPATH
elif echo "${FIRMWARE_INPUT}" | grep -q "${PROJECT_DIR}/input/" && [[ $(find "${INPUTDIR}" -maxdepth 1 -type f -size +300M -print | wc -l) -eq 1 ]]; then
	log_info "Input directory contains firmware file"
	cd "${INPUTDIR}/" || exit 1
	# Input File Variables
	FILEPATH=$(find "$(pwd)" -maxdepth 1 -type f -size +300M 2>/dev/null)
	FILE=${FILEPATH##*/}
	EXTENSION=${FILEPATH##*.}
	if echo "${EXTENSION}" | grep -q "zip\|rar\|7z\|tar$"; then
		UNZIP_DIR=${FILE%.*}
	fi
else
	# Attempt To Download File/Folder From Internet
	if util_is_url "${FIRMWARE_INPUT}"; then
		log_step "Downloading firmware from URL"
		URL=${FIRMWARE_INPUT}
		util_mkdir "${INPUTDIR}" || exit 1
		cd "${INPUTDIR}/" || exit 1
		util_remove "${INPUTDIR:?}"/*
		
		# Download using the new downloader library
		if ! download_file "${URL}" "${INPUTDIR}"; then
			log_fatal "Download failed"
			exit 1
		fi
		
		unset URL
		
		# Sanitize filenames
		for f in *; do
			if [[ -f "${f}" ]]; then
				if util_command_exists detox; then
					detox -r "${f}" 2>/dev/null
				fi
			fi
		done
		
		# Input File Variables
		FILEPATH=$(find "$(pwd)" -maxdepth 1 -type f 2>/dev/null)
		log_info "Working with: ${FILEPATH##*/}"
		
		# Check if multiple files or directory
		if [[ $(echo "${FILEPATH}" | tr ' ' '\n' | wc -l) -gt 1 ]]; then
			FILEPATH=$(find "$(pwd)" -maxdepth 2 -type d)
		fi
	else
		# For Local File/Folder
		log_step "Processing local firmware file/folder"
		FILEPATH=$(util_realpath "${FIRMWARE_INPUT}")
		
		# Sanitize filename if it has spaces
		if util_has_spaces "${FIRMWARE_INPUT}"; then
			if [[ -w "${FILEPATH}" ]]; then
				if util_command_exists detox; then
					detox -r "${FILEPATH}" 2>/dev/null
					# Try inline-detox if available, otherwise keep the detoxed path
					if util_command_exists inline-detox; then
						detoxed_path=$(echo "${FILEPATH}" | inline-detox 2>/dev/null)
						if [[ -n "${detoxed_path}" ]] && [[ -e "${detoxed_path}" ]]; then
							FILEPATH="${detoxed_path}"
						fi
					fi
					# Re-resolve path after detox
					FILEPATH=$(util_realpath "${FIRMWARE_INPUT}" 2>/dev/null) || FILEPATH="${FIRMWARE_INPUT}"
				fi
			fi
		fi
		
		if [[ ! -e "${FILEPATH}" ]]; then
			log_fatal "Input file/folder doesn't exist: ${FILEPATH}"
			exit 1
		fi
		
		log_info "Using local file: ${FILEPATH}"
	fi
	
	# Input File Variables
	FILE=${FILEPATH##*/}
	EXTENSION=${FILEPATH##*.}
	if echo "${EXTENSION}" | grep -q "zip\|rar\|7z\|tar$"; then
		UNZIP_DIR=${FILE%.*}
	fi
	
	if [[ -d "${FILEPATH}" || "${EXTENSION}" == "" ]]; then
		log_info "Directory detected"
		if find "${FILEPATH}" -maxdepth 1 -type f | grep -v "compatibility.zip" | grep -q ".*.tar$\|.*.zip\|.*.rar\|.*.7z"; then
			log_info "Folder contains compressed archive, re-loading"
			# Set From Download Directory
			ArcPath=$(find "${INPUTDIR}"/ -maxdepth 1 -type f \( -name "*.tar" -o -name "*.zip" -o -name "*.rar" -o -name "*.7z" \) -print | grep -v "compatibility.zip")
			# If Empty, Set From Original Local Folder
			[[ -z "${ArcPath}" ]] && ArcPath=$(find "${FILEPATH}"/ -maxdepth 1 -type f \( -name "*.tar" -o -name "*.zip" -o -name "*.rar" -o -name "*.7z" \) -print | grep -v "compatibility.zip")
			if ! echo "${ArcPath}" | grep -q " "; then
				# Assuming there's only one archive to re-load and process
				log_info "Re-loading archive: ${ArcPath}"
				cd "${PROJECT_DIR}/" || exit
				( bash "${0}" "${ArcPath}" ) || exit 1
				exit
			elif echo "${ArcPath}" | grep -q " "; then
				log_error "More than one archive file found in ${FILEPATH}"
				log_info "Please use direct archive path"
				exit 1
			fi
		elif find "${FILEPATH}" -maxdepth 1 -type f | grep ".*system.ext4.tar.*\|.*chunk\|system\/build.prop\|system.new.dat\|system_new.img\|system.img\|system-sign.img\|system.bin\|payload.bin\|.*rawprogram*\|system.sin\|.*system_.*\.sin\|system-p\|super\|UPDATE.APP\|.*.pac\|.*.nb0" | grep -q -v ".*chunk.*\.so$"; then
			log_info "Copying firmware files to temporary directory"
			util_copy "${FILEPATH}"/* "${TMPDIR}/" || exit 1
			unset FILEPATH
		else
			log_error "This type of firmware is not supported"
			util_remove "${TMPDIR}"
			util_remove "${OUTDIR}"
			exit 1
		fi
	fi
fi

cd "${PROJECT_DIR}/" || exit

# Function for Extracting Super Images
function superimage_extract() {
	log_step "Extracting partitions from Super image"
	if [ -f super.img ]; then
		log_debug "Converting sparse super image to raw"
		${SIMG2IMG} super.img super.img.raw 2>/dev/null
	fi
	if [[ ! -s super.img.raw ]] && [ -f super.img ]; then
		mv super.img super.img.raw
	fi
	for partition in $PARTITIONS; do
		($LPUNPACK --partition="$partition"_a super.img.raw || $LPUNPACK --partition="$partition" super.img.raw) 2>/dev/null
		if [ -f "$partition"_a.img ]; then
			mv "$partition"_a.img "$partition".img
		else
			foundpartitions=$(${BIN_7ZZ} l -ba "${FILEPATH}" | rev | gawk '{ print $1 }' | rev | grep "$partition".img)
			${BIN_7ZZ} e -y "${FILEPATH}" "$foundpartitions" dummypartition 2>/dev/null >> "$TMPDIR"/zip.log
		fi
	done
	rm -rf super.img.raw
	log_success "Super image extraction completed"
}

# ============================================================================
# IMAGE EXTRACTION FUNCTIONS
# ============================================================================

# Detect filesystem type of an image
function detect_filesystem() {
	local img_file="$1"
	local fs_type=""
	
	# Check for sparse image first
	if file "${img_file}" | grep -q "Android sparse image"; then
		echo "sparse"
		return 0
	fi
	
	# Try to detect filesystem using file command
	local file_output
	file_output=$(file "${img_file}")
	
	if echo "${file_output}" | grep -qi "ext[2-4]"; then
		echo "ext4"
	elif echo "${file_output}" | grep -qi "erofs"; then
		echo "erofs"
	elif echo "${file_output}" | grep -qi "f2fs"; then
		echo "f2fs"
	elif echo "${file_output}" | grep -qi "squashfs"; then
		echo "squashfs"
	else
		# Try fsck.erofs to detect EROFS
		if "${FSCK_EROFS}" --help >/dev/null 2>&1; then
			if "${FSCK_EROFS}" "${img_file}" >/dev/null 2>&1; then
				echo "erofs"
				return 0
			fi
		fi
		echo "unknown"
	fi
}

# Extract partition using 7z
function extract_with_7z() {
	local partition="$1"
	local img_file="$2"
	local output_dir="$3"
	
	log_debug "Attempting extraction with 7z..."
	
	# Create output directory
	mkdir -p "${output_dir}" 2>/dev/null
	
	# Try extraction with timeout and capture output
	local extract_output
	extract_output=$(timeout 300 ${BIN_7ZZ} x -snld "${img_file}" -y -o"${output_dir}/" 2>&1)
	local extract_status=$?
	
	# Check extraction status
	if [[ ${extract_status} -eq 0 ]]; then
		# Verify that files were actually extracted
		if [[ -n "$(find "${output_dir}" -type f -print -quit 2>/dev/null)" ]]; then
			log_debug "Successfully extracted with 7z"
			return 0
		else
			log_warn "7z completed but no files extracted"
			return 1
		fi
	elif [[ ${extract_status} -eq 124 ]]; then
		log_warn "7z extraction timed out after 5 minutes"
		return 1
	else
		log_debug "7z extraction failed with status ${extract_status}"
		# Check if it's a "not archive" error
		if echo "${extract_output}" | grep -qi "Can't open\|is not archive\|Unsupported"; then
			log_debug "File is not a valid 7z/ext4 archive"
		fi
		return 1
	fi
}

# Extract partition using fsck.erofs
function extract_with_erofs() {
	local partition="$1"
	local img_file="$2"
	local output_dir="$3"
	
	log_debug "Attempting extraction with fsck.erofs..."
	
	# Check if fsck.erofs is available and functional
	if ! command -v "${FSCK_EROFS}" >/dev/null 2>&1; then
		log_debug "fsck.erofs not found"
		return 1
	fi
	
	# Create output directory
	mkdir -p "${output_dir}" 2>/dev/null
	
	# Try extraction with timeout to prevent hanging
	local extract_output
	extract_output=$(timeout 300 "${FSCK_EROFS}" --extract="${output_dir}" "${img_file}" 2>&1)
	local extract_status=$?
	
	# Check if extraction was successful
	if [[ ${extract_status} -eq 0 ]]; then
		# Verify that files were actually extracted
		if [[ -n "$(find "${output_dir}" -type f -print -quit 2>/dev/null)" ]]; then
			log_debug "Successfully extracted with fsck.erofs"
			return 0
		else
			log_warn "fsck.erofs completed but no files extracted"
			return 1
		fi
	elif [[ ${extract_status} -eq 124 ]]; then
		log_warn "fsck.erofs extraction timed out after 5 minutes"
		return 1
	else
		log_debug "fsck.erofs extraction failed with status ${extract_status}"
		# Show relevant error messages only
		echo "${extract_output}" | grep -i "error\|fail\|invalid" | head -5
		return 1
	fi
}

# Extract partition using mount loop
function extract_with_mount() {
	local partition="$1"
	local img_file="$2"
	local output_dir="$3"
	local temp_mount="${output_dir}_mount_tmp"
	
	log_debug "Attempting extraction with mount loop..."
	
	# Create temporary mount point
	mkdir -p "${temp_mount}" 2>/dev/null
	
	# Try to mount with specific filesystem types
	local mount_success=false
	local fs_types=("auto" "erofs" "ext4" "f2fs")
	
	for fs_type in "${fs_types[@]}"; do
		if sudo mount -o loop,ro -t "${fs_type}" "${img_file}" "${temp_mount}" 2>/dev/null; then
			log_debug "Successfully mounted ${partition} as ${fs_type}"
			mount_success=true
			break
		fi
	done
	
	if ! ${mount_success}; then
		log_warn "Failed to mount ${partition}"
		rm -rf "${temp_mount}"
		return 1
	fi
	
	# Copy contents using simple cp approach (memory efficient, proven to work)
	log_info "Copying files from mount (this may take a while for large partitions)..."
	
	# Create temporary output directory for copying
	local temp_output="${output_dir}_tmp"
	mkdir -p "${temp_output}" 2>/dev/null
	
	# Copy files from mount to temporary directory
	log_debug "Copying files from mount..."
	sudo cp -rf "${temp_mount}/." "${temp_output}/" 2>/dev/null
	local cp_result=$?
	
	# Unmount the image
	sudo umount "${temp_mount}" 2>/dev/null
	rm -rf "${temp_mount}"
	
	if [ ${cp_result} -eq 0 ]; then
		# Move files from temporary to final output directory
		mkdir -p "${output_dir}" 2>/dev/null
		if sudo cp -rf "${temp_output}/." "${output_dir}/" 2>/dev/null; then
			sudo rm -rf "${temp_output}"
			
			# Fix permissions
			sudo chown -R "$(whoami)" "${output_dir}/" 2>/dev/null
			chmod -R u+rwX "${output_dir}/" 2>/dev/null
			
			log_debug "Successfully copied files from mount"
			return 0
		else
			log_error "Failed to copy files from temporary directory to output directory"
			sudo rm -rf "${temp_output}"
			return 1
		fi
	else
		log_error "Failed to copy files from mount"
		sudo rm -rf "${temp_output}"
		return 1
	fi
}

# Extract a single partition image with automatic method detection
function extract_partition_image() {
	local partition="$1"
	local img_file="${partition}.img"
	local output_dir="${partition}"
	
	# Skip if image doesn't exist
	if [[ ! -f "${img_file}" ]]; then
		return 0
	fi
	
	# Skip special partitions
	if echo "${partition}" | grep -q "boot\|recovery\|dtbo\|vendor_boot\|tz\|modem"; then
		log_debug "Skipping special partition: ${partition}"
		return 0
	fi
	
	log_step "Extracting ${partition} partition"
	
	# Create output directory
	mkdir -p "${output_dir}" 2>/dev/null || rm -rf "${output_dir:?}"/*
	
	# Detect filesystem
	local fs_type
	fs_type=$(detect_filesystem "${img_file}")
	log_info "Detected filesystem: ${fs_type}"
	
	# Handle sparse images first
	if [[ "${fs_type}" == "sparse" ]]; then
		log_info "Converting sparse image to raw..."
		if "${SIMG2IMG}" "${img_file}" "${img_file}.raw" 2>/dev/null; then
			mv "${img_file}.raw" "${img_file}"
			fs_type=$(detect_filesystem "${img_file}")
			log_success "Sparse image converted, new filesystem: ${fs_type}"
		else
			log_warn "Failed to convert sparse image"
		fi
	fi
	
	# Try extraction methods in order based on filesystem type
	local extraction_success=false
	
	# For EROFS: Try mount first (most reliable), then fsck.erofs, then 7z
	if [[ "${fs_type}" == "erofs" ]]; then
		log_info "Trying mount loop extraction for EROFS..."
		if extract_with_mount "${partition}" "${img_file}" "${output_dir}"; then
			log_success "Extracted ${partition} with mount loop"
			rm -f "${img_file}" 2>/dev/null
			extraction_success=true
			return 0
		else
			log_warn "Mount loop extraction failed for ${partition}, trying fsck.erofs..."
		fi
		
		if extract_with_erofs "${partition}" "${img_file}" "${output_dir}"; then
			log_success "Extracted ${partition} with fsck.erofs"
			rm -f "${img_file}" 2>/dev/null
			extraction_success=true
			return 0
		else
			log_warn "fsck.erofs extraction failed for ${partition}"
		fi
	fi
	
	# For ext4 or unknown: Try 7z first (fast), then mount
	if [[ "${fs_type}" == "ext4" ]] || [[ "${fs_type}" == "unknown" ]]; then
		if extract_with_7z "${partition}" "${img_file}" "${output_dir}"; then
			log_success "Extracted ${partition} with 7z"
			rm -f "${img_file}" 2>/dev/null
			extraction_success=true
			return 0
		else
			log_warn "7z extraction failed for ${partition}"
		fi
	fi
	
	# For F2FS and other filesystems: Try mount directly
	if [[ "${fs_type}" == "f2fs" ]] || [[ "${fs_type}" == "squashfs" ]]; then
		log_info "Trying mount loop extraction for ${fs_type}..."
		if extract_with_mount "${partition}" "${img_file}" "${output_dir}"; then
			log_success "Extracted ${partition} with mount loop"
			rm -f "${img_file}" 2>/dev/null
			extraction_success=true
			return 0
		else
			log_warn "Mount loop extraction failed for ${partition}"
		fi
	fi
	
	# Last resort: Try mount loop for any remaining cases
	if ! ${extraction_success}; then
		log_info "Trying mount loop extraction as fallback..."
		if extract_with_mount "${partition}" "${img_file}" "${output_dir}"; then
			log_success "Extracted ${partition} with mount loop"
			rm -f "${img_file}" 2>/dev/null
			extraction_success=true
			return 0
		else
			log_warn "Mount loop extraction failed for ${partition}"
		fi
	fi
	
	# If all methods failed
	if ! ${extraction_success}; then
		log_error "Failed to extract ${partition} partition"
		log_error "Filesystem: ${fs_type}"
		log_error "Methods tried: 7z, fsck.erofs, mount loop"
		
		# Provide helpful error messages based on filesystem
		case "${fs_type}" in
			"erofs")
				log_error "EROFS requires Linux kernel 5.4+ and fsck.erofs tool"
				;;
			"f2fs")
				log_error "F2FS requires Linux kernel 5.15+ for proper support"
				;;
			"unknown")
				log_error "Unknown filesystem - image may be encrypted or corrupted"
				;;
		esac
		
		# Keep the image file for manual inspection
		log_info "Image file preserved for manual inspection: ${img_file}"
		return 1
	fi
	
	return 0
}

# Extract boot image components
function extract_boot_image() {
	local boot_type="$1"  # "boot", "vendor_boot", "recovery", "init_boot"
	local boot_img="${boot_type}.img"
	
	if [[ ! -f "${boot_img}" ]]; then
		return 0
	fi
	
	log_step "Extracting ${boot_type} image"
	
	# Create directories
	mkdir -p "${boot_type}" "${boot_type}img" "${boot_type}dts" "${boot_type}RE" 2>/dev/null
	
	# Extract DTB
	log_debug "Extracting device tree blobs..."
	if uvx -q extract-dtb "${boot_img}" -o "${boot_type}img" >/dev/null 2>&1; then
		# Convert DTB to DTS
		find "${boot_type}img" -name '*.dtb' -type f 2>/dev/null | while read -r dtb_file; do
			local dtb_name
			dtb_name=$(basename "${dtb_file}")
			local dts_name="${dtb_name/.dtb/.dts}"
			"${DTC}" -q -s -f -I dtb -O dts -o "${boot_type}dts/${dts_name}" "${dtb_file}" 2>/dev/null
		done
		log_debug "Device tree blobs extracted and converted"
	fi
	
	# Unpack boot image
	log_debug "Unpacking boot image structure..."
	if bash "${UNPACKBOOT}" "${boot_img}" "${boot_type}" 2>/dev/null; then
		log_debug "Boot image unpacked successfully"
	fi
	
	# Extract kernel config if present
	if [[ "${boot_type}" == "boot" ]] || [[ "${boot_type}" == "vendor_boot" ]]; then
		log_debug "Extracting kernel configuration..."
		bash "${EXTRACT_IKCONFIG}" "${boot_img}" > "${boot_type}RE/ikconfig" 2>/dev/null
		[[ ! -s "${boot_type}RE/ikconfig" ]] && rm -f "${boot_type}RE/ikconfig" 2>/dev/null
		
		# Extract kallsyms
		log_debug "Extracting kernel symbols..."
		if [[ -f "${boot_type}/kernel" ]]; then
			python3 "${KALLSYMS_FINDER}" "${boot_type}/kernel" > "${boot_type}RE/kernel_kallsyms.txt" 2>/dev/null
		else
			python3 "${KALLSYMS_FINDER}" "${boot_img}" > "${boot_type}RE/${boot_type}_kallsyms.txt" 2>/dev/null
		fi
		
		# Extract vmlinux
		log_debug "Extracting vmlinux ELF..."
		python3 "${VMLINUX2ELF}" "${boot_img}" "${boot_type}RE/${boot_type}.elf" 2>/dev/null
		
		# Extract DTB from unpacked boot
		if [[ -f "${boot_type}/dtb.img" ]]; then
			mkdir -p "dtbimg" 2>/dev/null
			uvx -q extract-dtb "${boot_type}/dtb.img" -o "dtbimg" >/dev/null 2>&1
		fi
	fi
	
	log_success "${boot_type^} image extracted successfully"
}

# Extract DTBO image
function extract_dtbo_image() {
	if [[ ! -f "dtbo.img" ]]; then
		return 0
	fi
	
	log_step "Extracting DTBO image"
	
	mkdir -p "dtbo" "dtbodts" 2>/dev/null
	
	# Extract DTB overlays
	if uvx -q extract-dtb "dtbo.img" -o "dtbo" >/dev/null 2>&1; then
		# Convert DTB to DTS
		find "dtbo" -name '*.dtb' -type f 2>/dev/null | while read -r dtb_file; do
			local dtb_name
			dtb_name=$(basename "${dtb_file}")
			local dts_name="${dtb_name/.dtb/.dts}"
			"${DTC}" -q -s -f -I dtb -O dts -o "dtbodts/${dts_name}" "${dtb_file}" 2>/dev/null
		done
		log_success "DTBO extracted successfully"
	else
		log_warn "Failed to extract DTBO"
	fi
}

log_header "Firmware Extraction Process"
log_info "Output directory: ${OUTDIR}"
cd "${TMPDIR}/" || exit

# Oppo .ozip Check
if [[ $(head -c12 "${FILEPATH}" 2>/dev/null | tr -d '\0') == "OPPOENCRYPT!" ]] || [[ "${EXTENSION}" == "ozip" ]]; then
	log_step "Oppo/Realme ozip firmware detected"
	# Either Move Downloaded/Re-Loaded File Or Copy Local File
	util_move "${INPUTDIR}/${FILE}" "${TMPDIR}/${FILE}" 2>/dev/null || util_copy "${FILEPATH}" "${TMPDIR}/${FILE}"
	log_info "Decrypting ozip and creating zip archive"
	uv run --with-requirements "${UTILSDIR}/oppo_decrypt/requirements.txt" "${OZIPDECRYPT}" "${TMPDIR}/${FILE}"
	util_mkdir "${INPUTDIR}"
	util_remove "${INPUTDIR:?}"/*
	if [[ -f "${FILE%.*}.zip" ]]; then
		util_move "${FILE%.*}.zip" "${INPUTDIR}/"
	elif [[ -d "${TMPDIR}"/out ]]; then
		mv "${TMPDIR}"/out/* "${INPUTDIR}"/
	fi
	rm -rf "${TMPDIR:?}"/*
	printf "Re-Loading The Decrypted Content.\n"
	cd "${PROJECT_DIR}"/ || exit
	( bash "${0}" "${PROJECT_DIR}/input/" 2>/dev/null || bash "${0}" "${INPUTDIR}"/"${FILE%.*}".zip ) || exit 1
	exit
fi
# Oneplus .ops Check
if ${BIN_7ZZ} l -ba "${FILEPATH}" | grep -q ".*.ops" 2>/dev/null; then
	log_step "Oppo/Oneplus ops firmware detected"
	log_info "Extracting ops file from archive..."
	foundops=$(${BIN_7ZZ} l -ba "${FILEPATH}" | gawk '{print $NF}' | grep ".*.ops")
	${BIN_7ZZ} e -y -- "${FILEPATH}" "${foundops}" */"${foundops}" 2>/dev/null >> "${TMPDIR}"/zip.log
	mkdir -p "${INPUTDIR}" 2>/dev/null && rm -rf -- "${INPUTDIR:?}"/* 2>/dev/null
	mv "$(echo "${foundops}" | gawk -F['/'] '{print $NF}')" "${INPUTDIR}"/
	sleep 1s
	log_info "Re-loading extracted ops file..."
	cd "${PROJECT_DIR}"/ || exit
	( bash "${0}" "${PROJECT_DIR}/input/${foundops}" 2>/dev/null) || exit 1
	exit
fi
if [[ "${EXTENSION}" == "ops" ]]; then
	log_step "Oppo/Oneplus ops firmware detected"
	# Either Move Downloaded/Re-Loaded File Or Copy Local File
	mv -f "${INPUTDIR}"/"${FILE}" "${TMPDIR}"/"${FILE}" 2>/dev/null || cp -a "${FILEPATH}" "${TMPDIR}"/"${FILE}"
	log_info "Decrypting and extracting ops file..."
	uv run --with-requirements "${UTILSDIR}/oppo_decrypt/requirements.txt" "${OPSDECRYPT}" decrypt "${TMPDIR}"/"${FILE}"
	mkdir -p "${INPUTDIR}" 2>/dev/null && rm -rf -- "${INPUTDIR:?}"/* 2>/dev/null
	mv "${TMPDIR}"/extract/* "${INPUTDIR}"/
	rm -rf "${TMPDIR:?}"/*
	log_info "Re-loading decrypted content..."
	cd "${PROJECT_DIR}"/ || exit
	( bash "${0}" "${PROJECT_DIR}/input/" 2>/dev/null || bash "${0}" "${INPUTDIR}"/"${FILE%.*}".zip ) || exit 1
	exit
fi
# Oppo .ofp Check
if ${BIN_7ZZ} l -ba "${FILEPATH}" | gawk '{print $NF}' | grep -q ".*.ofp" 2>/dev/null; then
	log_step "Oppo ofp firmware detected"
	log_info "Extracting ofp file from archive..."
	foundofp=$(${BIN_7ZZ} l -ba "${FILEPATH}" | gawk '{print $NF}' | grep ".*.ofp")
	${BIN_7ZZ} e -y -- "${FILEPATH}" "${foundofp}" */"${foundofp}" 2>/dev/null >> "${TMPDIR}"/zip.log
	mkdir -p "${INPUTDIR}" 2>/dev/null && rm -rf -- "${INPUTDIR:?}"/* 2>/dev/null
	mv "$(echo "${foundofp}" | gawk -F['/'] '{print $NF}')" "${INPUTDIR}"/
	sleep 1s
	log_info "Re-loading extracted ofp file..."
	cd "${PROJECT_DIR}"/ || exit
	( bash "${0}" "${PROJECT_DIR}/input/${foundofp}" 2>/dev/null) || exit 1
	exit
fi
if [[ "${EXTENSION}" == "ofp" ]]; then
	log_step "Oppo ofp firmware detected"
	# Either Move Downloaded/Re-Loaded File Or Copy Local File
	mv -f "${INPUTDIR}"/"${FILE}" "${TMPDIR}"/"${FILE}" 2>/dev/null || cp -a "${FILEPATH}" "${TMPDIR}"/"${FILE}"
	log_info "Decrypting and extracting ofp file..."
	uv run --with-requirements "${UTILSDIR}/oppo_decrypt/requirements.txt" "$OFP_QC_DECRYPT" "${TMPDIR}"/"${FILE}" out
	if [[ ! -f "${TMPDIR}"/out/boot.img || ! -f "${TMPDIR}"/out/userdata.img ]]; then
		log_debug "Trying MTK decryption method..."
		uv run --with-requirements "${UTILSDIR}/oppo_decrypt/requirements.txt" "$OFP_MTK_DECRYPT" "${TMPDIR}"/"${FILE}" out
		if [[ ! -f "${TMPDIR}"/out/boot.img || ! -f "${TMPDIR}"/out/userdata.img ]]; then
			log_error "OFP decryption failed" && exit 1
		fi
	fi
	mkdir -p "${INPUTDIR}" 2>/dev/null && rm -rf -- "${INPUTDIR:?}"/* 2>/dev/null
	if [[ -d "${TMPDIR}"/out ]]; then
		mv "${TMPDIR}"/out/* "${INPUTDIR}"/
	fi
	rm -rf "${TMPDIR:?}"/*
	log_info "Re-loading decrypted content..."
	cd "${PROJECT_DIR}"/ || exit
	( bash "${0}" "${PROJECT_DIR}/input/" ) || exit 1
	exit
fi
# Xiaomi .tgz Check
if [[ "${FILE##*.}" == "tgz" || "${FILE#*.}" == "tar.gz" ]]; then
	log_step "Xiaomi gzipped tar archive detected"
	mkdir -p "${INPUTDIR}" 2>/dev/null
	log_info "Extracting gzipped tar archive..."
	if [[ -f "${INPUTDIR}"/"${FILE}" ]]; then
		tar xzf "${INPUTDIR}"/"${FILE}" -C "${INPUTDIR}"/ --transform='s/.*\///' 2>/dev/null
		rm -rf -- "${INPUTDIR:?}"/"${FILE}"
	elif [[ -f "${FILEPATH}" ]]; then
		tar xzf "${FILEPATH}" -C "${INPUTDIR}"/ --transform='s/.*\///' 2>/dev/null
	fi
	find "${INPUTDIR}"/ -type d -empty -delete     # Delete Empty Folder Leftover
	rm -rf "${TMPDIR:?}"/*
	log_success "Archive extracted successfully"
	log_info "Re-loading extracted content..."
	cd "${PROJECT_DIR}"/ || exit
	( bash "${0}" "${PROJECT_DIR}/input/" ) || exit 1
	exit
fi
# LG KDZ Check
if echo "${FILEPATH}" | grep -q ".*.kdz" || [[ "${EXTENSION}" == "kdz" ]]; then
	log_step "LG KDZ firmware detected"
	# Either Move Downloaded/Re-Loaded File Or Copy Local File
	mv -f "${INPUTDIR}"/"${FILE}" "${TMPDIR}"/ 2>/dev/null || cp -a "${FILEPATH}" "${TMPDIR}"/
	log_info "Extracting KDZ archive..."
	python3 "${KDZ_EXTRACT}" -f "${FILE}" -x -o "./" 2>/dev/null
	DZFILE=$(ls -- *.dz)
	log_info "Extracting all partitions as individual images..."
	python3 "${DZ_EXTRACT}" -f "${DZFILE}" -s -o "./" 2>/dev/null
	rm -f "${TMPDIR}"/"${FILE}" "${TMPDIR}"/"${DZFILE}" 2>/dev/null
	# dzpartitions="gpt_main persist misc metadata vendor system system_other product userdata gpt_backup tz boot dtbo vbmeta cust oem odm factory modem NON-HLOS"
	find "${TMPDIR}" -maxdepth 1 -type f -name "*.image" | while read -r i; do mv "${i}" "${i/.image/.img}" 2>/dev/null; done
	find "${TMPDIR}" -maxdepth 1 -type f -name "*_a.img" | while read -r i; do mv "${i}" "${i/_a.img/.img}" 2>/dev/null; done
	find "${TMPDIR}" -maxdepth 1 -type f -name "*_b.img" -exec rm -rf {} \;
	log_success "LG KDZ extraction completed"
fi
# HTC RUU Check
if echo "${FILEPATH}" | grep -i "^ruu_" | grep -q -i "exe$" || [[ "${EXTENSION}" == "exe" ]]; then
	log_step "HTC RUU firmware detected"
	# Either Move Downloaded/Re-Loaded File Or Copy Local File
	mv -f "${INPUTDIR}"/"${FILE}" "${TMPDIR}"/ || cp -a "${FILEPATH}" "${TMPDIR}"/
	log_info "Extracting system and firmware partitions..."
	"${RUUDECRYPT}" -s "${FILE}" 2>/dev/null
	"${RUUDECRYPT}" -f "${FILE}" 2>/dev/null
	find "${TMPDIR}"/OUT* -name "*.img" -exec mv {} "${TMPDIR}"/ \;
	log_success "HTC RUU extraction completed"
fi

# Amlogic upgrade package (AML) Check
if ${BIN_7ZZ} l -ba "${FILEPATH}" | grep -qi aml; then
	log_step "Amlogic upgrade package detected"
	cp "${FILEPATH}" "${TMPDIR}"
	FILE="${TMPDIR}/$(basename "${FILEPATH}")"
	log_info "Extracting AML package..."
	${BIN_7ZZ} e -y "${FILEPATH}" >> "${TMPDIR}"/zip.log
	"${AML_EXTRACT}" "$(find . -type f -name "*aml*.img")"
	rename 's/.PARTITION$/.img/' ./*.PARTITION
	rename 's/_aml_dtb.img$/dtb.img/' ./*.img
	rename 's/_a.img/.img/' ./*.img
	if [[ -f super.img ]]; then
		superimage_extract || exit 1
	fi
	for partition in $PARTITIONS; do
		[[ -e "${TMPDIR}/${partition}.img" ]] && mv "${TMPDIR}/${partition}.img" "${OUTDIR}/${partition}.img"
	done
	rm -rf "${TMPDIR}"
	log_success "AML package extraction completed"
fi

# Extract & Move Raw Otherpartitons To OUTDIR
if [[ -f "${FILEPATH}" ]]; then
	other_partition_count=0
	for otherpartition in ${OTHERPARTITIONS}; do
		filename=${otherpartition%:*} && outname=${otherpartition#*:}
		if ${BIN_7ZZ} l -ba "${FILEPATH}" | grep -q "${filename}"; then
			((other_partition_count++))
			log_debug "Extracting ${filename} as ${outname}"
			foundfile=$(${BIN_7ZZ} l -ba "${FILEPATH}" | grep "${filename}" | awk '{print $NF}')
			${BIN_7ZZ} e -y -- "${FILEPATH}" "${foundfile}" */"${foundfile}" 2>/dev/null >> "${TMPDIR}"/zip.log
			output=$(ls -- "${filename}"* 2>/dev/null)
			[[ ! -e "${TMPDIR}"/"${outname}".img ]] && mv "${output}" "${TMPDIR}"/"${outname}".img
			"${SIMG2IMG}" "${TMPDIR}"/"${outname}".img "${OUTDIR}"/"${outname}".img 2>/dev/null
			[[ ! -s "${OUTDIR}"/"${outname}".img && -f "${TMPDIR}"/"${outname}".img ]] && mv "${outname}".img "${OUTDIR}"/"${outname}".img
		fi
	done
	[[ ${other_partition_count} -gt 0 ]] && log_info "Extracted ${other_partition_count} additional partition(s)"
fi

# Extract/Put Image/Extra Files In TMPDIR
if ${BIN_7ZZ} l -ba "${FILEPATH}" | grep -q "system.new.dat" 2>/dev/null || [[ $(find "${TMPDIR}" -type f -name "system.new.dat*" -print | wc -l) -ge 1 ]]; then
	log_step "A-only DAT-formatted OTA detected"
	for partition in $PARTITIONS; do
		${BIN_7ZZ} e -y "${FILEPATH}" "${partition}".new.dat* "${partition}".transfer.list "${partition}".img 2>/dev/null >> "${TMPDIR}"/zip.log
		${BIN_7ZZ} e -y "${FILEPATH}" "${partition}".*".new.dat*" "${partition}".*".transfer.list" "${partition}".*".img" 2>/dev/null >> "${TMPDIR}"/zip.log
		rename 's/(\w+)\.(\d+)\.(\w+)/$1.$3/' *
		# For Oplus A-only OTAs, eg OnePlus Nord 2. Regex matches the 8 digits of Oplus NV ID (prop ro.build.oplus_nv_id) to remove them.
		# hello@world:~/test_regex# rename -n 's/(\w+)\.(\d+)\.(\w+)/$1.$3/' *
		# rename(my_bigball.00011011.new.dat.br, my_bigball.new.dat.br)
		# rename(my_bigball.00011011.patch.dat, my_bigball.patch.dat)
		# rename(my_bigball.00011011.transfer.list, my_bigball.transfer.list)
		if [[ -f ${partition}.new.dat.1 ]]; then
			cat "${partition}".new.dat.{0..999} 2>/dev/null >> "${partition}".new.dat
			rm -rf "${partition}".new.dat.{0..999}
		fi
		dat_files=()
		while IFS= read -r -d '' file; do
			dat_files+=("$file")
		done < <(find . -maxdepth 1 -name "*.new.dat*" -print0)
		
		for i in "${dat_files[@]}"; do
			line=$(basename "$i" | cut -d"." -f1)
			if [[ "$i" =~ \.dat\.xz$ ]]; then
				${BIN_7ZZ} e -y "$i" 2>/dev/null >> "${TMPDIR}"/zip.log
				rm -rf "$i"
			fi
			if [[ "$i" =~ \.dat\.br$ ]]; then
				log_debug "Converting brotli ${line} dat to normal"
				brotli -d "$i"
				rm -f "$i"
			fi
			if [[ "$i" =~ \.new\.dat$ ]]; then
				log_debug "Extracting ${line} partition"
				python3 "${SDAT2IMG}" "${line}".transfer.list "${line}".new.dat "${OUTDIR}"/"${line}".img > "${TMPDIR}"/extract.log
				rm -rf "${line}".transfer.list "${line}".new.dat
			fi
		done
	done
	log_success "DAT extraction completed"
elif ${BIN_7ZZ} l -ba "${FILEPATH}" | grep -q rawprogram || [[ $(find "${TMPDIR}" -type f -name "*rawprogram*" | wc -l) -ge 1 ]]; then
	log_step "QFIL firmware detected"
	rawprograms=$(${BIN_7ZZ} l -ba "${FILEPATH}" | gawk '{ print $NF }' | grep rawprogram)
	${BIN_7ZZ} e -y "${FILEPATH}" "$rawprograms" 2>/dev/null >> "${TMPDIR}"/zip.log
	log_info "Extracting partitions from QFIL package..."
	for partition in $PARTITIONS; do
		partitionsonzip=$(${BIN_7ZZ} l -ba "${FILEPATH}" | gawk '{ print $NF }' | grep "$partition")
		if [[ -n "$partitionsonzip" ]]; then
			${BIN_7ZZ} e -y "${FILEPATH}" "$partitionsonzip" 2>/dev/null >> "${TMPDIR}"/zip.log
			if [[ ! -f "$partition.img" ]]; then
				if [[ -f "$partition.raw.img" ]]; then
					mv "$partition.raw.img" "$partition.img"
				else
					rawprogramsfile=$(grep -rlw "$partition" rawprogram*.xml)
					"${PACKSPARSEIMG}" -t "$partition" -x "$rawprogramsfile" > "${TMPDIR}"/extract.log
					mv "$partition.raw" "$partition.img"
				fi
			fi
		fi
	done
	if [[ -f super.img ]]; then
		superimage_extract || exit 1
	fi
	log_success "QFIL extraction completed"
elif ${BIN_7ZZ} l -ba "${FILEPATH}" | grep -q ".*.nb0" 2>/dev/null || [[ $(find "${TMPDIR}" -type f -name "*.nb0*" | wc -l) -ge 1 ]]; then
	log_step "nb0-formatted firmware detected"
	if [[ -f "${FILEPATH}" ]]; then
		to_extract=$(${BIN_7ZZ} l -ba "${FILEPATH}" | grep ".*.nb0" | gawk '{print $NF}')
		${BIN_7ZZ} e -y -- "${FILEPATH}" "${to_extract}" 2>/dev/null >> "${TMPDIR}"/zip.log
	else
		find "${TMPDIR}" -type f -name "*.nb0*" -exec mv {} . \; 2>/dev/null
	fi
	log_info "Extracting nb0 firmware..."
	"${NB0_EXTRACT}" "${to_extract}" "${TMPDIR}"
	log_success "nb0 extraction completed"
elif ${BIN_7ZZ} l -ba "${FILEPATH}" | grep system | grep chunk | grep -q -v ".*\.so$" 2>/dev/null || [[ $(find "${TMPDIR}" -type f -name "*system*chunk*" | wc -l) -ge 1 ]]; then
	log_step "Chunk-formatted firmware detected"
	log_info "Extracting chunk files..."
	for partition in ${PARTITIONS}; do
		if [[ -f "${FILEPATH}" ]]; then
			foundpartitions=$(${BIN_7ZZ} l -ba "${FILEPATH}" | gawk '{print $NF}' | grep "${partition}".img)
			${BIN_7ZZ} e -y -- "${FILEPATH}" *"${partition}"*chunk* */*"${partition}"*chunk* "${foundpartitions}" dummypartition 2>/dev/null >> "${TMPDIR}"/zip.log
		else
			find "${TMPDIR}" -type f -name "*${partition}*chunk*" -exec mv {} . \; 2>/dev/null
			find "${TMPDIR}" -type f -name "*${partition}*.img" -exec mv {} . \; 2>/dev/null
		fi
		rm -f -- *"${partition}"_b*
		rm -f -- *"${partition}"_other*
		romchunk=$(find . -maxdepth 1 -type f -name "*${partition}*chunk*" | cut -d'/' -f'2-' | sort)
		if echo "${romchunk}" | grep -q "sparsechunk"; then
			if [[ ! -f "${partition}".img ]]; then
				"${SIMG2IMG}" "${romchunk}" "${partition}".img.raw 2>/dev/null
				mv "${partition}".img.raw "${partition}".img
			fi
			rm -rf -- *"${partition}"*chunk* 2>/dev/null
		fi
	done
	log_success "Chunk extraction completed"
elif ${BIN_7ZZ} l -ba "${FILEPATH}" | gawk '{print $NF}' | grep -q "system_new.img\|^system.img\|\/system.img\|\/system_image.emmc.img\|^system_image.emmc.img" 2>/dev/null || [[ $(find "${TMPDIR}" -type f -name "system*.img" | wc -l) -ge 1 ]]; then
	log_step "Image files detected"
	if [[ -f "${FILEPATH}" ]]; then
		log_info "Extracting image files..."
		${BIN_7ZZ} x -y "${FILEPATH}" 2>/dev/null >> "${TMPDIR}"/zip.log
	fi
	for f in "${TMPDIR}"/*; do detox -r "${f}" 2>/dev/null; done
	find "${TMPDIR}" -mindepth 2 -type f -name "*_image.emmc.img" | while read -r i; do mv "${i}" "${i/_image.emmc.img/.img}" 2>/dev/null; done
	find "${TMPDIR}" -mindepth 2 -type f -name "*_new.img" | while read -r i; do mv "${i}" "${i/_new.img/.img}" 2>/dev/null; done
	find "${TMPDIR}" -mindepth 2 -type f -name "*.img.ext4" | while read -r i; do mv "${i}" "${i/.img.ext4/.img}" 2>/dev/null; done
	find "${TMPDIR}" -mindepth 2 -type f -name "*.img" -exec mv {} . \;	# move .img in sub-dir to ${TMPDIR}
	### Keep some files, add script here to retain them
	find "${TMPDIR}" -type f -iname "*Android_scatter.txt" -exec mv {} "${OUTDIR}"/ \;
	find "${TMPDIR}" -type f -iname "*Release_Note.txt" -exec mv {} "${OUTDIR}"/ \;
	find "${TMPDIR}" -type f ! -name "*img*" -exec rm -rf {} \;	# delete other files
	find "${TMPDIR}" -maxdepth 3 -type f -name "*.img" -exec mv {} . \; 2>/dev/null
	log_success "Image extraction completed"
elif ${BIN_7ZZ} l -ba "${FILEPATH}" | grep -q "system.sin\|.*system_.*\.sin" 2>/dev/null || [[ $(find "${TMPDIR}" -type f -name "system*.sin" | wc -l) -ge 1 ]]; then
	log_step "Sony sin image detected"
	[[ -f "${FILEPATH}" ]] && ${BIN_7ZZ} x -y "${FILEPATH}" 2>/dev/null >> "${TMPDIR}"/zip.log
	log_info "Processing sin files..."
	# Remove Unnecessary Filename Part
	to_remove=$(find . -type f | grep ".*boot_.*\.sin" | gawk '{print $NF}' | sed -e 's/boot_\(.*\).sin/\1/')
	[[ -z "$to_remove" ]] && to_remove=$(find . -type f | grep ".*cache_.*\.sin" | gawk '{print $NF}' | sed -e 's/cache_\(.*\).sin/\1/')
	[[ -z "$to_remove" ]] && to_remove=$(find . -type f | grep ".*vendor_.*\.sin" | gawk '{print $NF}' | sed -e 's/vendor_\(.*\).sin/\1/')
	find "${TMPDIR}" -mindepth 2 -type f -name "*.sin" -exec mv {} . \;	# move .img in sub-dir to ${TMPDIR}
	find "${TMPDIR}" -maxdepth 1 -type f -name "*_${to_remove}.sin" | while read -r i; do mv "${i}" "${i/_${to_remove}.sin/.sin}" 2>/dev/null; done	# proper names
	"${UNSIN}" -d "${TMPDIR}"
	find "${TMPDIR}" -maxdepth 1 -type f -name "*.ext4" | while read -r i; do mv "${i}" "${i/.ext4/.img}" 2>/dev/null; done	# proper names
	foundsuperinsin=$(find "${TMPDIR}" -maxdepth 1 -type f -name "super_*.img")
	if [ ! -z "$foundsuperinsin" ]; then
		mv "${TMPDIR}"/super_*.img "${TMPDIR}/super.img" 2>/dev/null
		log_info "Super image detected inside sin file"
		superimage_extract || exit 1
	fi
	log_success "sin extraction completed"
elif ${BIN_7ZZ} l -ba "${FILEPATH}" | grep ".pac$" 2>/dev/null || [[ $(find "${TMPDIR}" -type f -name "*.pac" | wc -l) -ge 1 ]]; then
	log_step "PAC archive detected"
	[[ -f "${FILEPATH}" ]] && ${BIN_7ZZ} x -y "${FILEPATH}" 2>/dev/null >> "${TMPDIR}"/zip.log
	for f in "${TMPDIR}"/*; do detox -r "${f}"; done
	pac_list=$(find . -type f -name "*.pac" | cut -d'/' -f'2-' | sort)
	log_info "Extracting $(echo "${pac_list}" | wc -l) PAC file(s)..."
	for file in ${pac_list}; do
		python3 "${PACEXTRACTOR}" "${file}" "$(pwd)"
	done
	if [[ -f super.img ]]; then
		superimage_extract || exit 1
	fi
	log_success "PAC extraction completed"
elif ${BIN_7ZZ} l -ba "${FILEPATH}" | grep -q "system.bin" 2>/dev/null || [[ $(find "${TMPDIR}" -type f -name "system.bin" | wc -l) -ge 1 ]]; then
	log_step "Binary images detected"
	[[ -f "${FILEPATH}" ]] && ${BIN_7ZZ} x -y "${FILEPATH}" 2>/dev/null >> "${TMPDIR}"/zip.log
	log_info "Converting .bin files to .img..."
	find "${TMPDIR}" -mindepth 2 -type f -name "*.bin" -exec mv {} . \;	# move .img in sub-dir to ${TMPDIR}
	find "${TMPDIR}" -maxdepth 1 -type f -name "*.bin" | while read -r i; do mv "${i}" "${i/\.bin/.img}" 2>/dev/null; done	# proper names
	log_success "Binary image conversion completed"
elif ${BIN_7ZZ} l -ba "${FILEPATH}" | grep -q "system-p" 2>/dev/null || [[ $(find "${TMPDIR}" -type f -name "system-p*" | wc -l) -ge 1 ]]; then
	log_step "P-suffix images detected"
	log_info "Processing p-suffix partitions..."
	for partition in ${PARTITIONS}; do
		if [[ -f "${FILEPATH}" ]]; then
			foundpartitions=$(${BIN_7ZZ} l -ba "${FILEPATH}" | gawk '{print $NF}' | grep "${partition}-p")
			${BIN_7ZZ} e -y -- "${FILEPATH}" "${foundpartitions}" dummypartition 2>/dev/null >> "${TMPDIR}"/zip.log
		else
			foundpartitions=$(find . -type f -name "*${partition}-p*" | cut -d'/' -f'2-')
		fi
	[[ -n "${foundpartitions}" ]] && mv "$(ls "${partition}"-p*)" "${partition}".img
	done
	log_success "P-suffix extraction completed"
elif ${BIN_7ZZ} l -ba "${FILEPATH}" | grep -q "system-sign.img" 2>/dev/null || [[ $(find "${TMPDIR}" -type f -name "system-sign.img" | wc -l) -ge 1 ]]; then
	log_step "Signed images detected"
	[[ -f "${FILEPATH}" ]] && ${BIN_7ZZ} x -y "${FILEPATH}" 2>/dev/null >> "${TMPDIR}"/zip.log
	for f in "${TMPDIR}"/*; do detox -r "${f}"; done
	for partition in ${PARTITIONS}; do
		[[ -e "${TMPDIR}"/"${partition}".img ]] && mv "${TMPDIR}"/"${partition}".img "${OUTDIR}"/"${partition}".img
	done
	log_info "Processing signed images..."
	find "${TMPDIR}" -mindepth 2 -type f -name "*-sign.img" -exec mv {} . \;	# move .img in sub-dir to ${TMPDIR}
	find "${TMPDIR}" -type f ! -name "*-sign.img" -exec rm -rf {} \;	# delete other files
	find "${TMPDIR}" -maxdepth 1 -type f -name "*-sign.img" | while read -r i; do mv "${i}" "${i/-sign.img/.img}" 2>/dev/null; done	# proper .img names
	sign_list=$(find . -maxdepth 1 -type f -name "*.img" | cut -d'/' -f'2-' | sort)
	for file in ${sign_list}; do
		rm -rf "${TMPDIR}"/x.img >/dev/null 2>&1
		MAGIC=$(head -c4 "${TMPDIR}"/"${file}" | tr -d '\0')
		if [[ "${MAGIC}" == "SSSS" ]]; then
			printf "Cleaning %s with SSSS header\n" "${file}"
			# This Is For little_endian Arch
			offset_low=$(od -A n -x -j 60 -N 2 "${TMPDIR}"/"${file}" | sed 's/ //g')
			offset_high=$(od -A n -x -j 62 -N 2 "${TMPDIR}"/"${file}" | sed 's/ //g')
			offset_low=0x${offset_low:0-4}
			offset_high=0x${offset_high:0-4}
			offset_low=$(printf "%d" "${offset_low}")
			offset_high=$(printf "%d" "${offset_high}")
			offset=$((65536*offset_high+offset_low))
			dd if="${TMPDIR}"/"${file}" of="${TMPDIR}"/x.img iflag=count_bytes,skip_bytes bs=8192 skip=64 count=${offset} >/dev/null 2>&1
		else	# Header With BFBF Magic Or Another Unknowed Header
			dd if="${TMPDIR}"/"${file}" of="${TMPDIR}"/x.img bs=$((0x4040)) skip=1 >/dev/null 2>&1
		fi
	done
	log_success "Signed image processing completed"
elif [[ $(${BIN_7ZZ} l -ba "$FILEPATH" | grep "super.img") ]]; then
	log_step "Super image detected in archive"
	foundsupers=$(${BIN_7ZZ} l -ba "${FILEPATH}" | gawk '{ print $NF }' | grep "super.img")
	${BIN_7ZZ} e -y "${FILEPATH}" $foundsupers dummypartition 2>/dev/null >> ${TMPDIR}/zip.log
	# Use find instead of ls | grep
	superchunk=$(find . -maxdepth 1 -type f -name "*super*chunk*" | sort)
	if echo "$superchunk" | grep -q "sparsechunk"; then
		log_info "Converting sparse super chunks..."
		# Word splitting is intentional here - simg2img requires multiple files as separate arguments
		# shellcheck disable=SC2086
		"${SIMG2IMG}" ${superchunk} super.img.raw 2>/dev/null
		rm -rf ./*super*chunk*
	fi
	superimage_extract || exit 1
elif [[ $(find "${TMPDIR}" -type f -name "super*.*img" | wc -l) -ge 1 ]]; then
	log_step "Super image detected"
	if [[ -f "${FILEPATH}" ]]; then
		foundsupers=$(${BIN_7ZZ} l -ba "${FILEPATH}" | gawk '{print $NF}' | grep "super.*img")
		${BIN_7ZZ} e -y -- "${FILEPATH}" "${foundsupers}" dummypartition 2>/dev/null >> "${TMPDIR}"/zip.log
	fi
	# Use find instead of ls | grep
	splitsupers=$(find . -maxdepth 1 -type f -name "super.[0-9]*.img" | sort)
	if [[ -n "${splitsupers}" ]]; then
		log_info "Creating super.img from split files..."
		# Word splitting is intentional here - simg2img requires multiple files as separate arguments
		# shellcheck disable=SC2086
		"${SIMG2IMG}" ${splitsupers} super.img.raw 2>/dev/null
		rm -rf ${splitsupers}
	fi
	superchunk=$(find . -maxdepth 1 -type f -name "*super*chunk*" | cut -d'/' -f'2-' | sort)
	if echo "${superchunk}" | grep -q "sparsechunk"; then
		log_info "Creating super.img from sparse chunks..."
		"${SIMG2IMG}" ${superchunk} super.img.raw 2>/dev/null
		rm -rf -- *super*chunk*
	fi
	superimage_extract || exit 1
elif ${BIN_7ZZ} l -ba "${FILEPATH}" | grep tar.md5 | gawk '{print $NF}' | grep -q AP_ 2>/dev/null || [[ $(find "${TMPDIR}" -type f -name "*AP_*tar.md5" | wc -l) -ge 1 ]]; then
	log_step "Samsung AP tar.md5 firmware detected"
	#mv -f "${FILEPATH}" "${TMPDIR}"/
	[[ -f "${FILEPATH}" ]] && ${BIN_7ZZ} e -y "${FILEPATH}" 2>/dev/null >> "${TMPDIR}"/zip.log
	
	# Extract tar.md5 archives
	tarmd5_files=(*.tar.md5)
	tarmd5_count=${#tarmd5_files[@]}
	if [[ -e "${tarmd5_files[0]}" ]]; then
		log_info "Extracting ${tarmd5_count} tar.md5 archive(s)..."
		for i in "${tarmd5_files[@]}"; do
			tar -xf "${i}" || exit 1
			rm -f "${i}" || exit 1
		done
		log_success "Extracted ${tarmd5_count} tar.md5 archive(s)"
	fi
	
	# Extract lz4 archives
	lz4_files=(*.lz4)
	if [[ -e "${lz4_files[0]}" ]]; then
		lz4_count=${#lz4_files[@]}
		log_info "Extracting ${lz4_count} lz4 archive(s)..."
		for f in "${lz4_files[@]}"; do
			lz4 -dc "${f}" > "${f/.lz4/}" || exit 1
			rm -f "${f}" || exit 1
		done
		log_success "Extracted ${lz4_count} lz4 archive(s)"
	fi
	
	# Rename Samsung ext4 files
	ext4_files=()
	while IFS= read -r -d '' file; do
		ext4_files+=("$file")
	done < <(find -maxdepth 1 -type f -name '*.ext4' -printf '%P\0')
	
	if [[ ${#ext4_files[@]} -gt 0 ]]; then
		log_debug "Renaming ${#ext4_files[@]} ext4 file(s)..."
		for samsung_ext4_img_files in "${ext4_files[@]}"; do
			mv "${samsung_ext4_img_files}" "${samsung_ext4_img_files%%.ext4}"
		done
	fi
	
	if [[ -f super.img ]]; then
		superimage_extract || exit 1	
	fi
	if [[ ! -f system.img ]]; then
		log_error "Extraction failed - system.img not found"
		rm -rf "${TMPDIR}" && exit 1
	fi
elif ${BIN_7ZZ} l -ba "${FILEPATH}" | grep -q payload.bin 2>/dev/null || [[ $(find "${TMPDIR}" -type f -name "payload.bin" | wc -l) -ge 1 ]]; then
	log_step "AB OTA payload.bin detected"
	log_info "Extracting payload using $(nproc --all) CPU cores..."
	${PAYLOAD_EXTRACTOR} -c "$(nproc --all)" -o "${TMPDIR}" "${FILEPATH}" >/dev/null
	log_success "Payload extraction completed"
elif ${BIN_7ZZ} l -ba "${FILEPATH}" | grep ".*.rar\|.*.zip\|.*.7z\|.*.tar$" 2>/dev/null || [[ $(find "${TMPDIR}" -type f \( -name "*.rar" -o -name "*.zip" -o -name "*.7z" -o -name "*.tar" \) | wc -l) -ge 1 ]]; then
	log_step "Compressed archive firmware detected"
	if [[ -f "${FILEPATH}" ]]; then
		mkdir -p "${TMPDIR}"/"${UNZIP_DIR}" 2>/dev/null
		log_info "Extracting archive..."
		${BIN_7ZZ} e -y "${FILEPATH}" -o"${TMPDIR}"/"${UNZIP_DIR}"  >> "${TMPDIR}"/zip.log
		for f in "${TMPDIR}"/"${UNZIP_DIR}"/*; do detox -r "${f}" 2>/dev/null; done
	fi
	zip_list=$(find ./"${UNZIP_DIR}" -type f -size +300M \( -name "*.rar" -o -name "*.zip" -o -name "*.7z" -o -name "*.tar" \) | cut -d'/' -f'2-' | sort)
	mkdir -p "${INPUTDIR}" 2>/dev/null
	rm -rf "${INPUTDIR:?}"/* 2>/dev/null
	for file in ${zip_list}; do
		mv "${TMPDIR}"/"${file}" "${INPUTDIR}"/
		rm -rf "${TMPDIR:?}"/*
		log_info "Re-loading nested archive..."
		cd "${PROJECT_DIR}"/ || exit
		( bash "${0}" "${INPUTDIR}"/"${file}" ) || exit 1
		exit
	done
	rm -rf "${TMPDIR:?}"/"${UNZIP_DIR}"
elif ${BIN_7ZZ} l -ba "${FILEPATH}" | grep -q "UPDATE.APP" 2>/dev/null || [[ $(find "${TMPDIR}" -type f -name "UPDATE.APP") ]]; then
	log_step "Huawei UPDATE.APP detected"
	[[ -f "${FILEPATH}" ]] && ${BIN_7ZZ} x "${FILEPATH}" UPDATE.APP 2>/dev/null >> "${TMPDIR}"/zip.log
	find "${TMPDIR}" -type f -name "UPDATE.APP" -exec mv {} . \;
	log_info "Extracting partitions from UPDATE.APP..."
	python3 "${SPLITUAPP}" -f "UPDATE.APP" -l super preas preavs || (
	for partition in ${PARTITIONS}; do
		python3 "${SPLITUAPP}" -f "UPDATE.APP" -l "${partition/.img/}" || log_debug "${partition} not found in UPDATE.APP"
	done )
	find output/ -type f -name "*.img" -exec mv {} . \;	# Partitions Are Extracted In "output" Folder
	if [[ -f super.img ]]; then
		log_info "Creating super.img from sparse files..."
		"${SIMG2IMG}" super.img super_* super.img.raw 2>/dev/null
		[[ ! -s super.img.raw && -f super.img ]] && mv super.img super.img.raw
	fi
	superimage_extract || exit 1
	log_success "UPDATE.APP extraction completed"
elif ${BIN_7ZZ} l -ba "${FILEPATH}" | grep -q "rockchip" 2>/dev/null || [[ $(find "${TMPDIR}" -type f -name "rockchip") ]]; then
	log_step "Rockchip firmware detected"
	log_info "Extracting Rockchip firmware..."
	${RK_EXTRACT} -unpack "${FILEPATH}" ${TMPDIR}
	${AFPTOOL_EXTRACT} -unpack ${TMPDIR}/firmware.img ${TMPDIR}
	[ -f ${TMPDIR}/Image/super.img ] && {
		mv ${TMPDIR}/Image/super.img ${TMPDIR}/super.img
		cd ${TMPDIR}
		superimage_extract || exit 1
		cd -
	}
	for partition in $PARTITIONS; do
		[[ -e "${TMPDIR}/Image/${partition}.img" ]] && mv "${TMPDIR}/Image/${partition}.img" "${OUTDIR}/${partition}.img"
		[[ -e "${TMPDIR}/${partition}.img" ]] && mv "${TMPDIR}/${partition}.img" "${OUTDIR}/${partition}.img"
	done
	log_success "Rockchip extraction completed"
fi

# PAC Archive Check
if [[ "${EXTENSION}" == "pac" ]]; then
	log_step "PAC archive detected"
	log_info "Extracting PAC archive..."
	python3 ${PACEXTRACTOR} ${FILEPATH} $(pwd)
	superimage_extract || exit 1
	log_success "PAC extraction completed"
	exit
fi

# $(pwd) == "${TMPDIR}"

# Process All otherpartitions From TMPDIR Now
other_parts_processed=0
for otherpartition in ${OTHERPARTITIONS}; do
	filename=${otherpartition%:*} && outname=${otherpartition#*:}
	output=$(ls -- "${filename}"* 2>/dev/null)
	if [[ -f "${output}" ]]; then
		((other_parts_processed++))
		log_debug "Processing ${filename} as ${outname}"
		[[ ! -e "${TMPDIR}"/"${outname}".img ]] && mv "${output}" "${TMPDIR}"/"${outname}".img
		"${SIMG2IMG}" "${TMPDIR}"/"${outname}".img "${OUTDIR}"/"${outname}".img 2>/dev/null
		[[ ! -s "${OUTDIR}"/"${outname}".img && -f "${TMPDIR}"/"${outname}".img ]] && mv "${outname}".img "${OUTDIR}"/"${outname}".img
	fi
done
[[ ${other_parts_processed} -gt 0 ]] && log_info "Processed ${other_parts_processed} additional partition(s)"

# Process All partitions From TMPDIR Now
for partition in ${PARTITIONS}; do
	if [[ ! -f "${partition}".img ]]; then
		foundpart=$(${BIN_7ZZ} l -ba "${FILEPATH}" | gawk '{print $NF}' | grep "${partition}.img" 2>/dev/null)
		${BIN_7ZZ} e -y -- "${FILEPATH}" "${foundpart}" */"${foundpart}" 2>/dev/null >> "${TMPDIR}"/zip.log
	fi
	[[ -f "${partition}".img ]] && "${SIMG2IMG}" "${partition}".img "${OUTDIR}"/"${partition}".img 2>/dev/null
	[[ ! -s "${OUTDIR}"/"${partition}".img && -f "${TMPDIR}"/"${partition}".img ]] && mv "${TMPDIR}"/"${partition}".img "${OUTDIR}"/"${partition}".img
	if [[ "${EXT4PARTITIONS}" =~ (^|[[:space:]])"${partition}"($|[[:space:]]) && -f "${OUTDIR}"/"${partition}".img ]]; then
		MAGIC=$(head -c12 "${OUTDIR}"/"${partition}".img | tr -d '\0')
		offset=$(LANG=C grep -aobP -m1 '\x53\xEF' "${OUTDIR}"/"${partition}".img | head -1 | gawk '{print $1 - 1080}')
		if echo "${MAGIC}" | grep -q "MOTO"; then
			[[ "$offset" == 128055 ]] && offset=131072
			printf "MOTO header detected on %s in %s\n" "${partition}" "${offset}"
		elif echo "${MAGIC}" | grep -q "ASUS"; then
			printf "ASUS header detected on %s in %s\n" "${partition}" "${offset}"
		else
			offset=0
		fi
		if [[ ! "${offset}" == "0" ]]; then
			dd if="${OUTDIR}"/"${partition}".img of="${OUTDIR}"/"${partition}".img-2 ibs=$offset skip=1 2>/dev/null
			mv -f "${OUTDIR}"/"${partition}".img-2 "${OUTDIR}"/"${partition}".img
		fi
	fi
	[[ ! -s "${OUTDIR}"/"${partition}".img && -f "${OUTDIR}"/"${partition}".img ]] && rm "${OUTDIR}"/"${partition}".img
done

cd "${OUTDIR}"/ || exit
rm -rf "${TMPDIR:?}"/*

# ============================================================================
# PARTITION EXTRACTION PHASE
# ============================================================================

log_header "Partition Extraction Phase"

# Extract boot images using new modular functions
extract_boot_image "boot"
extract_boot_image "vendor_boot"
extract_boot_image "recovery"
extract_boot_image "init_boot"
extract_boot_image "vendor_kernel_boot"

# Extract DTBO
extract_dtbo_image

# Extract all regular partitions with improved logic
log_step "Extracting regular partitions"
partitions_extracted=0
partitions_failed=0

for p in $PARTITIONS; do
	if extract_partition_image "${p}"; then
		((partitions_extracted++))
	else
		((partitions_failed++))
	fi
done

if [[ ${partitions_extracted} -gt 0 ]]; then
	log_success "Successfully extracted ${partitions_extracted} partition(s)"
fi

if [[ ${partitions_failed} -gt 0 ]]; then
	log_warn "${partitions_failed} partition(s) failed to extract"
fi

# Remove Unnecessary Image Leftover From OUTDIR
log_debug "Cleaning up unnecessary image files..."
for q in *.img; do
	if ! echo "${q}" | grep -q "boot\|recovery\|dtbo\|tz\|optics\|omr\|prism\|persist"; then
		rm -f "${q}" 2>/dev/null
	fi
done

# Oppo/Realme Devices Have Some Images In A Euclid Folder In Their Vendor and/or System, Extract Those For Props
log_debug "Checking for Euclid images..."
for dir in "vendor/euclid" "system/system/euclid"; do
	if [[ -d "${dir}" ]]; then
		pushd "${dir}" >/dev/null || continue
		for f in *.img; do
			[[ -f "${f}" ]] || continue
			log_debug "Extracting Euclid image: ${f}"
			${BIN_7ZZ} x "${f}" -o"${f/.img/}" >/dev/null 2>&1
			rm -f "${f}"
		done
		popd >/dev/null || exit 1
	fi
done

# board-info.txt
find "${OUTDIR}"/modem -type f -exec strings {} \; 2>/dev/null | grep "QC_IMAGE_VERSION_STRING=MPSS." | sed "s|QC_IMAGE_VERSION_STRING=MPSS.||g" | cut -c 4- | sed -e 's/^/require version-baseband=/' >> "${TMPDIR}"/board-info.txt
find "${OUTDIR}"/tz* -type f -exec strings {} \; 2>/dev/null | grep "QC_IMAGE_VERSION_STRING" | sed "s|QC_IMAGE_VERSION_STRING|require version-trustzone|g" >> "${TMPDIR}"/board-info.txt
if [ -e "${OUTDIR}"/vendor/build.prop ]; then
	strings "${OUTDIR}"/vendor/build.prop | grep "ro.vendor.build.date.utc" | sed "s|ro.vendor.build.date.utc|require version-vendor|g" >> "${TMPDIR}"/board-info.txt
fi
sort -u < "${TMPDIR}"/board-info.txt > "${OUTDIR}"/board-info.txt

# set variables
[[ $(find "$(pwd)"/system "$(pwd)"/system/system "$(pwd)"/vendor "$(pwd)"/*product -maxdepth 1 -type f -name "build*.prop" 2>/dev/null | sort -u | gawk '{print $NF}') ]] || { printf "No system/vendor/product build*.prop found, pushing cancelled.\n" && exit 1; }

flavor=$(grep -m1 -oP "(?<=^ro.build.flavor=).*" -hs {system,system/system,vendor}/build*.prop)
[[ -z "${flavor}" ]] && flavor=$(grep -m1 -oP "(?<=^ro.vendor.build.flavor=).*" -hs vendor/build*.prop)
[[ -z "${flavor}" ]] && flavor=$(grep -m1 -oP "(?<=^ro.system.build.flavor=).*" -hs {system,system/system}/build*.prop)
[[ -z "${flavor}" ]] && flavor=$(grep -m1 -oP "(?<=^ro.build.type=).*" -hs {system,system/system}/build*.prop)
release=$(grep -m1 -oP "(?<=^ro.build.version.release=).*" -hs {system,system/system,vendor}/build*.prop)
[[ -z "${release}" ]] && release=$(grep -m1 -oP "(?<=^ro.vendor.build.version.release=).*" -hs vendor/build*.prop)
[[ -z "${release}" ]] && release=$(grep -m1 -oP "(?<=^ro.system.build.version.release=).*" -hs {system,system/system}/build*.prop)
id=$(grep -m1 -oP "(?<=^ro.build.id=).*" -hs {system,system/system,vendor}/build*.prop)
[[ -z "${id}" ]] && id=$(grep -m1 -oP "(?<=^ro.vendor.build.id=).*" -hs vendor/build*.prop)
[[ -z "${id}" ]] && id=$(grep -m1 -oP "(?<=^ro.system.build.id=).*" -hs {system,system/system}/build*.prop)
tags=$(grep -m1 -oP "(?<=^ro.build.tags=).*" -hs {system,system/system,vendor}/build*.prop)
[[ -z "${tags}" ]] && tags=$(grep -m1 -oP "(?<=^ro.vendor.build.tags=).*" -hs vendor/build*.prop)
[[ -z "${tags}" ]] && tags=$(grep -m1 -oP "(?<=^ro.system.build.tags=).*" -hs {system,system/system}/build*.prop)
platform=$(grep -m1 -oP "(?<=^ro.board.platform=).*" -hs {system,system/system,vendor}/build*.prop | head -1)
[[ -z "${platform}" ]] && platform=$(grep -m1 -oP "(?<=^ro.vendor.board.platform=).*" -hs vendor/build*.prop)
[[ -z "${platform}" ]] && platform=$(grep -m1 -oP "(?<=^ro.system.board.platform=).*" -hs {system,system/system}/build*.prop)
manufacturer=$(grep -m1 -oP "(?<=^ro.product.manufacturer=).*" -hs {system,system/system,vendor}/build*.prop | head -1)
[[ -z "${manufacturer}" ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.product.brand.sub=).*" -hs system/system/euclid/my_product/build*.prop)
[[ -z "${manufacturer}" ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.vendor.product.manufacturer=).*" -hs vendor/build*.prop | head -1)
[[ -z "${manufacturer}" ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.product.vendor.manufacturer=).*" -hs vendor/build*.prop | head -1)
[[ -z "${manufacturer}" ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.system.product.manufacturer=).*" -hs {system,system/system}/build*.prop)
[[ -z "${manufacturer}" ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.product.system.manufacturer=).*" -hs {system,system/system}/build*.prop)
[[ -z "${manufacturer}" ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.product.odm.manufacturer=).*" -hs vendor/odm/etc/build*.prop)
[[ -z "${manufacturer}" ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.product.manufacturer=).*" -hs {oppo_product,my_product,product}/build*.prop | head -1)
[[ -z "${manufacturer}" ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.product.manufacturer=).*" -hs vendor/euclid/*/build.prop)
[[ -z "${manufacturer}" ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.system.product.manufacturer=).*" -hs vendor/euclid/*/build.prop)
[[ -z "${manufacturer}" ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.product.product.manufacturer=).*" -hs vendor/euclid/product/build*.prop)
[[ -z "${manufacturer}" ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.product.vendor.manufacturer=).*" -hs vendor/build*.prop)
[[ -z "${manufacturer}" ]] && manufacturer=$(grep -m1 -oP "(?<=^ro.product.system.manufacturer=).*" -hs {system,system/system}/build*.prop)
fingerprint=$(grep -m1 -oP "(?<=^ro.build.fingerprint=).*" -hs {system,system/system}/build*.prop)
[[ -z "${fingerprint}" ]] && fingerprint=$(grep -m1 -oP "(?<=^ro.vendor.build.fingerprint=).*" -hs vendor/build*.prop | head -1)
[[ -z "${fingerprint}" ]] && fingerprint=$(grep -m1 -oP "(?<=^ro.system.build.fingerprint=).*" -hs {system,system/system}/build*.prop)
[[ -z "${fingerprint}" ]] && fingerprint=$(grep -m1 -oP "(?<=^ro.product.build.fingerprint=).*" -hs product/build*.prop)
[[ -z "${fingerprint}" ]] && fingerprint=$(grep -m1 -oP "(?<=^ro.build.fingerprint=).*" -hs {oppo_product,my_product}/build*.prop)
[[ -z "${fingerprint}" ]] && fingerprint=$(grep -m1 -oP "(?<=^ro.system.build.fingerprint=).*" -hs my_product/build.prop)
[[ -z "${fingerprint}" ]] && fingerprint=$(grep -m1 -oP "(?<=^ro.vendor.build.fingerprint=).*" -hs my_product/build.prop)
[[ -z "${fingerprint}" ]] && fingerprint=$(grep -m1 -oP "(?<=^ro.bootimage.build.fingerprint=).*" -hs vendor/build.prop)
brand=$(grep -m1 -oP "(?<=^ro.product.brand=).*" -hs {system,system/system,vendor}/build*.prop | head -1)
[[ -z "${brand}" ]] && brand=$(grep -m1 -oP "(?<=^ro.product.brand.sub=).*" -hs system/system/euclid/my_product/build*.prop)
[[ -z "${brand}" ]] && brand=$(grep -m1 -oP "(?<=^ro.product.vendor.brand=).*" -hs vendor/build*.prop | head -1)
[[ -z "${brand}" ]] && brand=$(grep -m1 -oP "(?<=^ro.vendor.product.brand=).*" -hs vendor/build*.prop | head -1)
[[ -z "${brand}" ]] && brand=$(grep -m1 -oP "(?<=^ro.product.system.brand=).*" -hs {system,system/system}/build*.prop | head -1)
[[ -z "${brand}" || ${brand} == "OPPO" ]] && brand=$(grep -m1 -oP "(?<=^ro.product.system.brand=).*" -hs vendor/euclid/*/build.prop | head -1)
[[ -z "${brand}" ]] && brand=$(grep -m1 -oP "(?<=^ro.product.product.brand=).*" -hs vendor/euclid/product/build*.prop)
[[ -z "${brand}" ]] && brand=$(grep -m1 -oP "(?<=^ro.product.odm.brand=).*" -hs vendor/odm/etc/build*.prop)
[[ -z "${brand}" ]] && brand=$(grep -m1 -oP "(?<=^ro.product.brand=).*" -hs {oppo_product,my_product}/build*.prop | head -1)
[[ -z "${brand}" ]] && brand=$(grep -m1 -oP "(?<=^ro.product.brand=).*" -hs vendor/euclid/*/build.prop | head -1)
[[ -z "${brand}" ]] && brand=$(echo "$fingerprint" | cut -d'/' -f1)
codename=$(grep -m1 -oP "(?<=^ro.product.device=).*" -hs {vendor,system,system/system}/build*.prop | head -1)
[[ -z "${codename}" ]] && codename=$(grep -m1 -oP "(?<=^ro.vendor.product.device.oem=).*" -hs vendor/euclid/odm/build.prop | head -1)
[[ -z "${codename}" ]] && codename=$(grep -m1 -oP "(?<=^ro.product.vendor.device=).*" -hs vendor/build*.prop | head -1)
[[ -z "${codename}" ]] && codename=$(grep -m1 -oP "(?<=^ro.vendor.product.device=).*" -hs vendor/build*.prop | head -1)
[[ -z "${codename}" ]] && codename=$(grep -m1 -oP "(?<=^ro.product.system.device=).*" -hs {system,system/system}/build*.prop | head -1)
[[ -z "${codename}" ]] && codename=$(grep -m1 -oP "(?<=^ro.product.system.device=).*" -hs vendor/euclid/*/build.prop | head -1)
[[ -z "${codename}" ]] && codename=$(grep -m1 -oP "(?<=^ro.product.product.device=).*" -hs vendor/euclid/*/build.prop | head -1)
[[ -z "${codename}" ]] && codename=$(grep -m1 -oP "(?<=^ro.product.product.model=).*" -hs vendor/euclid/*/build.prop | head -1)
[[ -z "${codename}" ]] && codename=$(grep -m1 -oP "(?<=^ro.product.device=).*" -hs {oppo_product,my_product}/build*.prop | head -1)
[[ -z "${codename}" ]] && codename=$(grep -m1 -oP "(?<=^ro.product.product.device=).*" -hs oppo_product/build*.prop)
[[ -z "${codename}" ]] && codename=$(grep -m1 -oP "(?<=^ro.product.system.device=).*" -hs my_product/build*.prop)
[[ -z "${codename}" ]] && codename=$(grep -m1 -oP "(?<=^ro.product.vendor.device=).*" -hs my_product/build*.prop)
[[ -z "${codename}" ]] && codename=$(echo "$fingerprint" | cut -d'/' -f3 | cut -d':' -f1)
[[ -z "${codename}" ]] && codename=$(grep -m1 -oP "(?<=^ro.build.fota.version=).*" -hs {system,system/system}/build*.prop | cut -d'-' -f1 | head -1)
[[ -z "${codename}" ]] && codename=$(grep -oP "(?<=^ro.build.product=).*" -hs {vendor,system,system/system}/build*.prop | head -1)
description=$(grep -m1 -oP "(?<=^ro.build.description=).*" -hs {system,system/system,vendor}/build*.prop | head -1)
[[ -z "${description}" ]] && description=$(grep -m1 -oP "(?<=^ro.vendor.build.description=).*" -hs vendor/build*.prop)
[[ -z "${description}" ]] && description=$(grep -m1 -oP "(?<=^ro.system.build.description=).*" -hs {system,system/system}/build*.prop)
[[ -z "${description}" ]] && description=$(grep -m1 -oP "(?<=^ro.product.build.description=).*" -hs product/build.prop)
[[ -z "${description}" ]] && description=$(grep -m1 -oP "(?<=^ro.product.build.description=).*" -hs product/build*.prop)
incremental=$(grep -m1 -oP "(?<=^ro.build.version.incremental=).*" -hs {system,system/system,vendor}/build*.prop | head -1)
[[ -z "${incremental}" ]] && incremental=$(grep -m1 -oP "(?<=^ro.vendor.build.version.incremental=).*" -hs vendor/build*.prop)
[[ -z "${incremental}" ]] && incremental=$(grep -m1 -oP "(?<=^ro.system.build.version.incremental=).*" -hs {system,system/system}/build*.prop | head -1)
[[ -z "${incremental}" ]] && incremental=$(grep -m1 -oP "(?<=^ro.build.version.incremental=).*" -hs my_product/build*.prop)
[[ -z "${incremental}" ]] && incremental=$(grep -m1 -oP "(?<=^ro.system.build.version.incremental=).*" -hs my_product/build*.prop)
[[ -z "${incremental}" ]] && incremental=$(grep -m1 -oP "(?<=^ro.vendor.build.version.incremental=).*" -hs my_product/build*.prop)
# For Realme devices with empty incremental & fingerprint,
[[ -z "${incremental}" && "${brand}" =~ "realme" ]] && incremental=$(grep -m1 -oP "(?<=^ro.build.version.ota=).*" -hs {vendor/euclid/product,oppo_product}/build.prop | rev | cut -d'_' -f'1-2' | rev)
[[ -z "${incremental}" && ! -z "${description}" ]] && incremental=$(echo "${description}" | cut -d' ' -f4)
[[ -z "${description}" && ! -z "${incremental}" ]] && description="${flavor} ${release} ${id} ${incremental} ${tags}"
[[ -z "${description}" && -z "${incremental}" ]] && description="${codename}"
abilist=$(grep -m1 -oP "(?<=^ro.product.cpu.abilist=).*" -hs {system,system/system}/build*.prop | head -1)
[[ -z "${abilist}" ]] && abilist=$(grep -m1 -oP "(?<=^ro.vendor.product.cpu.abilist=).*" -hs vendor/build*.prop)
locale=$(grep -m1 -oP "(?<=^ro.product.locale=).*" -hs {system,system/system}/build*.prop | head -1)
[[ -z "${locale}" ]] && locale=undefined
density=$(grep -m1 -oP "(?<=^ro.sf.lcd_density=).*" -hs {system,system/system}/build*.prop | head -1)
[[ -z "${density}" ]] && density=undefined
is_ab=$(grep -m1 -oP "(?<=^ro.build.ab_update=).*" -hs {system,system/system,vendor}/build*.prop)
[[ -z "${is_ab}" ]] && is_ab="false"
treble_support=$(grep -m1 -oP "(?<=^ro.treble.enabled=).*" -hs {system,system/system}/build*.prop)
[[ -z "${treble_support}" ]] && treble_support="false"
otaver=$(grep -m1 -oP "(?<=^ro.build.version.ota=).*" -hs {vendor/euclid/product,oppo_product,system,system/system}/build*.prop | head -1)
[[ ! -z "${otaver}" && -z "${fingerprint}" ]] && branch=$(echo "${otaver}" | tr ' ' '-')
[[ -z "${otaver}" ]] && otaver=$(grep -m1 -oP "(?<=^ro.build.fota.version=).*" -hs {system,system/system}/build*.prop | head -1)
[[ -z "${branch}" ]] && branch=$(echo "${description}" | tr ' ' '-')

if [[ "$PUSH_TO_GITLAB" = true ]]; then
	rm -rf .github_token
	repo=$(printf "${brand}" | tr '[:upper:]' '[:lower:]' && echo -e "/${codename}")
else
	rm -rf .gitlab_token
	repo=$(echo "${brand}"_"${codename}"_dump | tr '[:upper:]' '[:lower:]')
fi

platform=$(echo "${platform}" | tr '[:upper:]' '[:lower:]' | tr -dc '[:print:]' | tr '_' '-' | cut -c 1-35)
top_codename=$(echo "${codename}" | tr '[:upper:]' '[:lower:]' | tr -dc '[:print:]' | tr '_' '-' | cut -c 1-35)
manufacturer=$(echo "${manufacturer}" | tr '[:upper:]' '[:lower:]' | tr -dc '[:print:]' | tr '_' '-' | cut -c 1-35)
[ -f "bootRE/ikconfig" ] && kernel_version=$(cat bootRE/ikconfig | grep "Kernel Configuration" | head -1 | awk '{print $3}')
# Repo README File
printf "## %s\n- Manufacturer: %s\n- Platform: %s\n- Codename: %s\n- Brand: %s\n- Flavor: %s\n- Release Version: %s\n- Kernel Version: %s\n- Id: %s\n- Incremental: %s\n- Tags: %s\n- CPU Abilist: %s\n- A/B Device: %s\n- Treble Device: %s\n- Locale: %s\n- Screen Density: %s\n- Fingerprint: %s\n- OTA version: %s\n- Branch: %s\n- Repo: %s\n" "${description}" "${manufacturer}" "${platform}" "${codename}" "${brand}" "${flavor}" "${release}" "${kernel_version}" "${id}" "${incremental}" "${tags}" "${abilist}" "${is_ab}" "${treble_support}" "${locale}" "${density}" "${fingerprint}" "${otaver}" "${branch}" "${repo}" > "${OUTDIR}"/README.md
cat "${OUTDIR}"/README.md

# Generate TWRP Trees
twrpdtout="twrp-device-tree"
if [[ "$is_ab" = true ]]; then
	if [ -f recovery.img ]; then
		printf "Legacy A/B with recovery partition detected...\n"
		twrpimg="recovery.img"
	else
	twrpimg="boot.img"
	fi
else
	twrpimg="recovery.img"
fi
if [[ -f ${twrpimg} ]]; then
	mkdir -p $twrpdtout
	uvx -p 3.9 --from git+https://github.com/twrpdtgen/twrpdtgen@master twrpdtgen $twrpimg -o $twrpdtout
	if [[ "$?" = 0 ]]; then
		[[ ! -e "${OUTDIR}"/twrp-device-tree/README.md ]] && curl https://raw.githubusercontent.com/wiki/SebaUbuntu/TWRP-device-tree-generator/4.-Build-TWRP-from-source.md > ${twrpdtout}/README.md
	fi
fi

# Remove all .git directories from twrpdtout
rm -rf $(find $twrpdtout -type d -name ".git")

# copy file names
chown "$(whoami)" ./* -R
chmod -R u+rwX ./*		#ensure final permissions
find "$OUTDIR" -type f -printf '%P\n' | sort | grep -v ".git/" > "$OUTDIR"/all_files.txt

# Generate LineageOS Trees
if [[ "$treble_support" = true ]]; then
        aospdtout="aosp-device-tree"
        mkdir -p $aospdtout
        uvx -p 3.9 aospdtgen $OUTDIR -o $aospdtout

        # Remove all .git directories from aospdtout
        rm -rf $(find $aospdtout -type d -name ".git")

        # Regenerate all_files.txt
        find "$OUTDIR" -type f -printf '%P\n' | sort | grep -v ".git/" > "$OUTDIR"/all_files.txt
fi

# Generate Files having the sha1sum values of the Blobs
function write_sha1sum(){
	# Usage: write_sha1sum <file> <destination_file>

	local SRC_FILE=$1
	local DST_FILE=$2

	# Temporary file
	local TMP_FILE=${SRC_FILE}.sha1sum.tmp
	
	# Get rid of all the Blank lines and Comments
	( cat ${SRC_FILE} | grep -v '^[[:space:]]*$' | grep -v "# " ) > ${TMP_FILE}

	# Append the sha1sum of blobs in the Destination File
	cp ${SRC_FILE} ${DST_FILE}
	cat ${TMP_FILE} | while read -r i; do {
		local BLOB=${i}

		# Do we have a "-" before the blob's path? If yes, then remove it
		local BLOB_TOPDIR=$(echo ${BLOB} | cut -d / -f1)
		[ "${BLOB_TOPDIR:0:1}" = "-" ] && local BLOB=${BLOB_TOPDIR/-/}/${BLOB/${BLOB_TOPDIR}\//}

		# Is it a non- /vendor blob?
		[ ! -e "${BLOB}" ] && {
			# for system libs, bins etc.
			if [ -e "system/${BLOB}" ]; then
				local BLOB="system/${BLOB}"
			# for system-as-root system libs, bins etc.
			elif [ -e "system/system/${BLOB}" ]; then
				local BLOB="system/system/${BLOB}"
			fi
		}
		local SHA1=$(sha1sum ${BLOB} | gawk '{print $1}')

		local BLOB=${i} # Switch back to the Original Blob's name
		local ORG_EXP="${BLOB}"
		local FINAL_EXP="${BLOB}|${SHA1}"

		# Append the |sha1sum
		sed -i "s:${ORG_EXP}$:${FINAL_EXP}:g" "${DST_FILE}"
	}; done

	# Delete the Temporary file
	rm ${TMP_FILE}
}

# Generate proprietary-files.txt
printf "Generating proprietary-files.txt...\n"
bash "${UTILSDIR}"/android_tools/tools/proprietary-files.sh "${OUTDIR}"/all_files.txt >/dev/null
printf "# All blobs from %s, unless pinned\n" "${description}" > "${OUTDIR}"/proprietary-files.txt
cat "${UTILSDIR}"/android_tools/working/proprietary-files.txt >> "${OUTDIR}"/proprietary-files.txt

# Generate proprietary-files.sha1
printf "Generating proprietary-files.sha1...\n"
printf "# All blobs are from \"%s\" and are pinned with sha1sum values\n" "${description}" > "${OUTDIR}"/proprietary-files.sha1
write_sha1sum ${UTILSDIR}/android_tools/working/proprietary-files.{txt,sha1}
cat "${UTILSDIR}"/android_tools/working/proprietary-files.sha1 >> "${OUTDIR}"/proprietary-files.sha1

# Stash the changes done at ${UTILSDIR}/android_tools
git -C "${UTILSDIR}"/android_tools/ add --all
git -C "${UTILSDIR}"/android_tools/ stash

# Generate all_files.sha1
printf "Generating all_files.sha1...\n"
write_sha1sum "$OUTDIR"/all_files.{txt,sha1.tmp}
( cat "$OUTDIR"/all_files.sha1.tmp | grep -v all_files.txt ) > "$OUTDIR"/all_files.sha1		# all_files.txt will be regenerated
rm -rf "$OUTDIR"/all_files.sha1.tmp

# Regenerate all_files.txt
printf "Generating all_files.txt...\n"
find "$OUTDIR" -type f -printf '%P\n' | sort | grep -v ".git/" > "$OUTDIR"/all_files.txt

rm -rf "${TMPDIR}" 2>/dev/null

# Helper function to push with retry logic
git_push_with_retry() {
	# Use new git_upload library for better handling
	if [[ -f "${PROJECT_DIR}/lib/git_upload.sh" ]]; then
		source "${PROJECT_DIR}/lib/git_upload.sh"
		
		# Configure git for large repo
		git_configure_large_repo "." || return 1
		
		# Ensure branch exists and has commits before pushing
		if ! git rev-parse --verify "${branch}" >/dev/null 2>&1; then
			log_warn "Branch '${branch}' does not exist, will be created with first commit"
		fi
		
		# Check if there are any commits on the current branch
		if ! git log -1 >/dev/null 2>&1; then
			log_warn "No commits found on branch ${branch}"
			log_info "Creating initial commit if staging area has files..."
			
			# Check if there are staged changes
			if ! git diff --cached --quiet 2>/dev/null; then
				log_info "Staging area has files, committing them"
				git commit -sm "Initial commit for ${description:-firmware dump}" || {
					log_error "Failed to create initial commit"
					return 1
				}
			else
				log_warn "No staged files to commit - push will be skipped"
				return 0  # Return success as there's nothing to push
			fi
		fi
		
		# Use improved push with retry
		local max_attempts=10
		local attempt=1
		local wait_time=5
		local max_wait=300  # 5 minutes max
		
		while [ $attempt -le $max_attempts ]; do
			log_info "Attempting to push (attempt $attempt/$max_attempts)..."
			
			# Try push with detailed logging
			if git push --progress -u origin "${branch}" 2>&1 | tee /tmp/git_push_output_$$.log; then
				log_success "Push successful!"
				rm -f /tmp/git_push_output_$$.log
				return 0
			else
				local exit_code=$?
				log_warn "Push failed with exit code $exit_code"
				
				# Analyze the error
				if grep -q "src refspec.*does not match any" /tmp/git_push_output_$$.log; then
					log_error "Branch ${branch} does not exist or has no commits"
					log_error "This should not happen as we checked earlier"
					rm -f /tmp/git_push_output_$$.log
					return 1
				elif grep -q "HTTP 50[023]" /tmp/git_push_output_$$.log; then
					log_warn "Server error detected (HTTP 500/502/503)"
					# Increase buffer size
					git config http.postBuffer 1048576000  # 1GB
					git config http.version HTTP/1.1
				elif grep -q "RPC failed" /tmp/git_push_output_$$.log; then
					log_warn "RPC failed - adjusting settings"
					git config pack.windowMemory 128m
					git config pack.packSizeLimit 128m
				elif grep -q "too large" /tmp/git_push_output_$$.log || grep -q "larger than" /tmp/git_push_output_$$.log; then
					log_error "Files too large - consider using Git LFS"
					# Enable LFS tracking for large files
					git lfs install 2>/dev/null
					find . -type f -size +50M -not -path ".git/*" | while read -r largefile; do
						git lfs track "$largefile" 2>/dev/null
					done
				elif grep -q "failed to push some refs" /tmp/git_push_output_$$.log; then
					log_warn "Push rejected - checking for diverged history"
				fi
				
				if [ $attempt -lt $max_attempts ]; then
					log_info "Waiting ${wait_time} seconds before retry..."
					sleep $wait_time
					# Exponential backoff with cap
					wait_time=$((wait_time * 2))
					if [ $wait_time -gt $max_wait ]; then
						wait_time=$max_wait
					fi
					attempt=$((attempt + 1))
				else
					log_error "Failed to push after $max_attempts attempts"
					log_info "Last error output:"
					tail -20 /tmp/git_push_output_$$.log
					rm -f /tmp/git_push_output_$$.log
					return 1
				fi
			fi
		done
		rm -f /tmp/git_push_output_$$.log
	else
		# Fallback to original implementation
		local max_attempts=5
		local attempt=1
		local wait_time=10
		
		# Ensure there are commits before pushing
		if ! git log -1 >/dev/null 2>&1; then
			echo "No commits found - creating initial commit if needed"
			if ! git diff --cached --quiet 2>/dev/null; then
				git commit -sm "Initial commit for ${description:-firmware dump}" || return 1
			else
				echo "No staged files to commit"
				return 0
			fi
		fi
		
		while [ $attempt -le $max_attempts ]; do
			echo "Attempting to push (attempt $attempt/$max_attempts)..."
			if git push -u origin "${branch}"; then
				echo "Push successful!"
				return 0
			else
				local exit_code=$?
				echo "Push failed with exit code $exit_code"
				if [ $attempt -lt $max_attempts ]; then
					echo "Waiting ${wait_time} seconds before retry..."
					sleep $wait_time
					# Exponential backoff
					wait_time=$((wait_time * 2))
					attempt=$((attempt + 1))
				else
					echo "ERROR: Failed to push after $max_attempts attempts"
					return 1
				fi
			fi
		done
	fi
}

# Helper function to split a large directory into multiple parts
split_and_push_directory() {
	local dir_name="$1"
	local dir_path="$2"
	local exclude_pattern="$3"
	local num_parts="${4:-3}"  # Default to 3 parts if not specified
	
	if [ ! -d "$dir_path" ]; then
		return 0
	fi
	
	# Get all subdirectories in the directory
	local SUBDIRS=()
	while IFS= read -r -d '' subdir; do
		local dirname=$(basename "$subdir")
		# Skip excluded patterns if provided
		if [ -n "$exclude_pattern" ] && [[ "$dirname" =~ $exclude_pattern ]]; then
			continue
		fi
		SUBDIRS+=("$dirname")
	done < <(find "$dir_path" -maxdepth 1 -type d -not -path "$dir_path" -print0 2>/dev/null | sort -z)
	
	# Calculate how many subdirs per part (ceiling division)
	local total=${#SUBDIRS[@]}
	local part_size=$(( (total + num_parts - 1) / num_parts ))  # Ceiling division
	
	# Push subdirectories in multiple parts
	for (( part=1; part<=num_parts; part++ )); do
		local start_idx=$(( (part - 1) * part_size ))
		local end_idx=$(( part * part_size ))
		
		# Add subdirectories for this part
		local has_content=false
		for (( idx=$start_idx; idx<$end_idx && idx<$total; idx++ )); do
			local subdir="${SUBDIRS[$idx]}"
			if [ -d "$dir_path/$subdir" ]; then
				git add "$dir_path/$subdir"
				has_content=true
			fi
		done
		
		# Also handle root-level files for the first part (excluding .spv and .png files)
		if [ $part -eq 1 ]; then
			# Check if there are any root-level files (excluding .spv and .png files)
			if [ -n "$(find "$dir_path" -maxdepth 1 -type f ! -name '*.spv' ! -name '*.png' 2>/dev/null)" ]; then
				find "$dir_path" -maxdepth 1 -type f ! -name '*.spv' ! -name '*.png' -exec git add {} \; 2>/dev/null
				has_content=true
			fi
		fi
		
		# Commit and push this part if there's content
		if [ "$has_content" = true ]; then
			# Only commit if there are staged changes (git diff returns non-zero when changes exist)
			if ! git diff --cached --quiet; then
				git commit -sm "Add ${dir_name} part ${part}/${num_parts} for ${description}"
				git_push_with_retry || return 1
			fi
		fi
	done
}

# Helper function to commit .spv and .png files separately
commit_binary_files_separately() {
	local dir_path="$1"
	local dir_name="$2"
	
	if [ ! -d "$dir_path" ]; then
		return 0
	fi
	
	# Commit .spv files separately
	if [ -n "$(find "$dir_path" -type f -name '*.spv' 2>/dev/null)" ]; then
		echo "Committing .spv files from ${dir_name} separately..."
		find "$dir_path" -type f -name '*.spv' -exec git add {} \; 2>/dev/null
		if ! git diff --cached --quiet; then
			git commit -sm "Add .spv files for ${description}"
			git_push_with_retry || return 1
		fi
	fi
	
	# Commit .png files separately
	if [ -n "$(find "$dir_path" -type f -name '*.png' 2>/dev/null)" ]; then
		echo "Committing .png files from ${dir_name} separately..."
		find "$dir_path" -type f -name '*.png' -exec git add {} \; 2>/dev/null
		if ! git diff --cached --quiet; then
			git commit -sm "Add .png files for ${description}"
			git_push_with_retry || return 1
		fi
	fi
}

commit_and_push(){
	local DIRS=(
		"product"
		"system_dlkm"
		"odm"
		"odm_dlkm"
		"vendor_dlkm"
		"optics"
		"omr"
		"prism"
		"persist"
	)

	# Initialize Git LFS with better tracking patterns
	log_step "Setting up Git LFS for large files"
	git lfs install 2>/dev/null
	
	# Track common large file types
	local lfs_patterns=(
		"*.so"
		"*.so.*"
		"*.apk"
		"*.jar"
		"*.ttf"
		"*.otf"
		"*.ttc"
		"*.png"
		"*.spv"
		"*.dat"
		"*.bin"
	)
	
	for pattern in "${lfs_patterns[@]}"; do
		git lfs track "$pattern" 2>/dev/null
	done
	
	# Track any remaining files > 50MB
	find . -type f -not -path ".git/*" -size +50M | while read -r largefile; do
		git lfs track "$largefile" 2>/dev/null
	done
	
	[ -e ".gitattributes" ] && {
		git add ".gitattributes"
		git commit -sm "Setup Git LFS for large files"
		git_push_with_retry || return 1
	}

	# Split APK files into smaller batches to avoid large commits
	local apk_files=()
	while IFS= read -r -d '' file; do
		apk_files+=("$file")
	done < <(find . -type f -name '*.apk' -print0 2>/dev/null)
	
	local apk_count=${#apk_files[@]}
	if [ $apk_count -gt 0 ]; then
		log_info "Found $apk_count APK files, splitting into batches..."
		local batch_size=30  # Reduced from 50 for safer pushes
		local batch_num=1
		local total_batches=$(( (apk_count + batch_size - 1) / batch_size ))
		
		for ((i=0; i<$apk_count; i+=batch_size)); do
			local batch=("${apk_files[@]:i:batch_size}")
			if [ ${#batch[@]} -gt 0 ]; then
				log_info "Adding APK batch $batch_num/$total_batches (${#batch[@]} files)..."
				git add "${batch[@]}"
				if ! git diff --cached --quiet; then
					git commit -sm "Add apps batch $batch_num/$total_batches for ${description}"
					git_push_with_retry || return 1
				fi
				batch_num=$((batch_num + 1))
			fi
		done
	fi

	for i in "${DIRS[@]}"; do
		local dir_added=false
		[ -d "${i}" ] && { git add "${i}"; dir_added=true; }
		[ -d system/"${i}" ] && { git add system/"${i}"; dir_added=true; }
		[ -d system/system/"${i}" ] && { git add system/system/"${i}"; dir_added=true; }
		[ -d vendor/"${i}" ] && { git add vendor/"${i}"; dir_added=true; }

		if [ "$dir_added" = true ] && ! git diff --cached --quiet; then
			git commit -sm "Add ${i} for ${description}"
			git_push_with_retry || return 1
		fi
	done

	# Split large directories into multiple parts to avoid HTTP 500 errors with large files
	
	# Commit .spv and .png files separately before splitting system directories
	commit_binary_files_separately "system" "system"
	commit_binary_files_separately "system/system" "system/system"
	
	# system_ext directory (no need to exclude system_* subdirs as they shouldn't exist here)
	split_and_push_directory "system_ext" "system_ext" '' 3
	[ -d system/system_ext ] && split_and_push_directory "system/system_ext" "system/system_ext" '' 3
	
	# vendor directory - increase splits to avoid large commits
	split_and_push_directory "vendor" "vendor" '' 5
	
	# system directory (excluding nested system_ext and system_dlkm already handled above)
	# Split into 8 parts to handle large number of files
	split_and_push_directory "system" "system" '^system_(ext|dlkm)$' 8

	# Commit individual firmware partitions separately
	local FIRMWARE_PARTITIONS=(
		"boot"
		"recovery" 
		"modem"
		"dtbo"
		"dtb"
		"vendor_boot"
		"init_boot"
		"vendor_kernel_boot"
		"tz"
	)
	
	for partition in "${FIRMWARE_PARTITIONS[@]}"; do
		local has_partition=false
		# Check for partition as directory
		if [ -d "${partition}" ]; then
			git add "${partition}"
			has_partition=true
		fi
		# Check for partition as file with common extensions
		for ext in img bin mbn; do
			if [ -f "${partition}.${ext}" ]; then
				git add "${partition}.${ext}"
				has_partition=true
			fi
		done
		# Only commit if we actually added something
		if [ "$has_partition" = true ]; then
			if ! git diff --cached --quiet; then
				git commit -sm "Add ${partition} for ${description}"
				git_push_with_retry || return 1
			fi
		fi
	done

	# Split remaining files into smaller chunks instead of one large commit
	echo "Adding remaining files in smaller batches..."
	local remaining_files=()
	while IFS= read -r -d '' file; do
		remaining_files+=("$file")
	done < <(git ls-files --others --exclude-standard -z 2>/dev/null)
	
	local remaining_count=${#remaining_files[@]}
	
	if [ $remaining_count -gt 0 ]; then
		echo "Found $remaining_count remaining files, splitting into batches..."
		local file_batch_size=100
		local file_batch_num=1
		local total_file_batches=$(( (remaining_count + file_batch_size - 1) / file_batch_size ))
		
		for ((i=0; i<$remaining_count; i+=file_batch_size)); do
			local file_batch=("${remaining_files[@]:i:file_batch_size}")
			if [ ${#file_batch[@]} -gt 0 ]; then
				echo "Adding extras batch $file_batch_num/$total_file_batches (${#file_batch[@]} files)..."
				git add "${file_batch[@]}" 2>/dev/null
				if ! git diff --cached --quiet; then
					git commit -sm "Add extras batch $file_batch_num/$total_file_batches for ${description}"
					git_push_with_retry || return 1
				fi
				file_batch_num=$((file_batch_num + 1))
			fi
		done
	fi
	
	# Final check for any remaining unstaged files - use batching to avoid large commits
	local final_files=()
	while IFS= read -r -d '' file; do
		final_files+=("$file")
	done < <(git ls-files --others --exclude-standard -z 2>/dev/null)
	
	if [ ${#final_files[@]} -gt 0 ]; then
		echo "Found ${#final_files[@]} final unstaged files, adding in batches..."
		local final_batch_size=50
		local final_batch_num=1
		local total_final_batches=$(( (${#final_files[@]} + final_batch_size - 1) / final_batch_size ))
		
		for ((i=0; i<${#final_files[@]}; i+=final_batch_size)); do
			local final_batch=("${final_files[@]:i:final_batch_size}")
			if [ ${#final_batch[@]} -gt 0 ]; then
				echo "Adding final batch $final_batch_num/$total_final_batches (${#final_batch[@]} files)..."
				git add "${final_batch[@]}" 2>/dev/null
				if ! git diff --cached --quiet; then
					git commit -sm "Add final extras batch $final_batch_num/$total_final_batches for ${description}"
					git_push_with_retry || return 1
				fi
				final_batch_num=$((final_batch_num + 1))
			fi
		done
	fi
}

split_files(){
	# usage: split_files <min_file_size> <part_size>
	# Files larger than ${1} will be split into ${2} parts as *.aa, *.ab, etc.
	mkdir -p "${TMPDIR}" 2>/dev/null
	find . -size +${1} | cut -d'/' -f'2-' >| "${TMPDIR}"/.largefiles
	if [[ -s "${TMPDIR}"/.largefiles ]]; then
		printf '#!/bin/bash\n\n' > join_split_files.sh
		while read -r l; do
			split -b ${2} "${l}" "${l}".
			rm -f "${l}" 2>/dev/null
			printf "cat %s.* 2>/dev/null >> %s\n" "${l}" "${l}" >> join_split_files.sh
			printf "rm -f %s.* 2>/dev/null\n" "${l}" >> join_split_files.sh
		done < "${TMPDIR}"/.largefiles
		chmod a+x join_split_files.sh 2>/dev/null
	fi
	rm -rf "${TMPDIR}" 2>/dev/null
}

if [[ -s "${PROJECT_DIR}"/.github_token ]]; then
	GITHUB_TOKEN=$(< "${PROJECT_DIR}"/.github_token)	# Write Your Github Token In a Text File
	[[ -z "$(git config --get user.email)" ]] && git config user.email "guptasushrut@gmail.com"
	[[ -z "$(git config --get user.name)" ]] && git config user.name "Sushrut1101"
	if [[ -s "${PROJECT_DIR}"/.github_orgname ]]; then
		GIT_ORG=$(< "${PROJECT_DIR}"/.github_orgname)	# Set Your Github Organization Name
	else
		GIT_USER="$(git config --get user.name)"
		GIT_ORG="${GIT_USER}"				# Otherwise, Your Username will be used
	fi
	# Check if already dumped or not
	curl -sf "https://raw.githubusercontent.com/${GIT_ORG}/${repo}/${branch}/all_files.txt" 2>/dev/null && { printf "Firmware already dumped!\nGo to https://github.com/%s/%s/tree/%s\n" "${GIT_ORG}" "${repo}" "${branch}" && exit 1; }
	# Remove The Journal File Inside System/Vendor
	find . -mindepth 2 -type d -name "\[SYS\]" -exec rm -rf {} \; 2>/dev/null
	split_files 62M 47M
	log_info "Final Repository Contents:"
	ls -lAog
	
	log_step "Initializing Git repository"
	git init
	
	# Use improved git configuration from git_upload library
	if [[ -f "${PROJECT_DIR}/lib/git_upload.sh" ]]; then
		source "${PROJECT_DIR}/lib/git_upload.sh"
		git_configure_large_repo "." || log_warn "Could not configure git optimally"
	else
		# Fallback to basic configuration
		git config http.postBuffer 524288000
		git config http.lowSpeedLimit 0
		git config http.lowSpeedTime 999999
		git config pack.windowMemory 256m
		git config pack.packSizeLimit 256m
		git config core.compression 0
	fi
	
	# Additional optimizations for GitHub
	git config http.version HTTP/1.1
	git config http.retryDelay 5
	git config http.retries 10
	git config core.bigFileThreshold 50m
	
	# Validate branch name before checkout
	if [[ -z "${branch}" ]]; then
		log_error "Branch name is empty! Using incremental as fallback"
		branch="${incremental}"
	fi
	
	if [[ -z "${branch}" ]]; then
		log_fatal "Cannot determine branch name - both description and incremental are empty"
		exit 1
	fi
	
	log_info "Creating git branch: ${branch}"
	git checkout -b "${branch}" || { 
		log_warn "Failed to create branch '${branch}', trying incremental '${incremental}'"
		git checkout -b "${incremental}" && export branch="${incremental}"
	}
	
	# Verify we're on the correct branch
	current_branch=$(git rev-parse --abbrev-ref HEAD)
	if [[ "${current_branch}" != "${branch}" ]]; then
		log_warn "Current branch '${current_branch}' differs from expected '${branch}'"
		branch="${current_branch}"
	fi
	
	log_success "Git branch created: ${branch}"
	
	find . \( -name "*sensetime*" -o -name "*.lic" \) | cut -d'/' -f'2-' >| .gitignore
	[[ ! -s .gitignore ]] && rm .gitignore
	
	log_step "Creating GitHub repository"
	if [[ "${GIT_ORG}" == "${GIT_USER}" ]]; then
		curl -s -X POST -H "Authorization: token ${GITHUB_TOKEN}" -d '{"name": "'"${repo}"'", "description": "'"${description}"'"}' "https://api.github.com/user/repos" >/dev/null 2>&1
	else
		curl -s -X POST -H "Authorization: token ${GITHUB_TOKEN}" -d '{ "name": "'"${repo}"'", "description": "'"${description}"'"}' "https://api.github.com/orgs/${GIT_ORG}/repos" >/dev/null 2>&1
	fi
	curl -s -X PUT -H "Authorization: token ${GITHUB_TOKEN}" -H "Accept: application/vnd.github.mercy-preview+json" -d '{ "names": ["'"${platform}"'","'"${manufacturer}"'","'"${top_codename}"'","firmware","dump"]}' "https://api.github.com/repos/${GIT_ORG}/${repo}/topics" 	# Update Repository Topics
	
	# Commit and Push
	log_header "Pushing Firmware to GitHub"
	log_info "Repository: https://github.com/${GIT_ORG}/${repo}.git"
	log_info "Branch: ${branch}"
	log_info "Description: ${description}"
	sleep 1
	git remote add origin https://${GITHUB_TOKEN}@github.com/${GIT_ORG}/${repo}.git
	commit_and_push
	sleep 1
	
	# Telegram channel post
	if [[ -s "${PROJECT_DIR}"/.tg_token ]]; then
		TG_TOKEN=$(< "${PROJECT_DIR}"/.tg_token)
		if [[ -s "${PROJECT_DIR}"/.tg_chat ]]; then		# TG Channel ID
			CHAT_ID=$(< "${PROJECT_DIR}"/.tg_chat)
		else
			CHAT_ID="@DumprXDumps"
		fi
		printf "Sending telegram notification...\n"
		printf "<b>Brand: %s</b>" "${brand}" >| "${OUTDIR}"/tg.html
		{
			printf "\n<b>Device: %s</b>" "${codename}"
			printf "\n<b>Platform: %s</b>" "${platform}"
			printf "\n<b>Android Version:</b> %s" "${release}"
			[ ! -z "${kernel_version}" ] && printf "\n<b>Kernel Version:</b> %s" "${kernel_version}"
			printf "\n<b>Fingerprint:</b> %s" "${fingerprint}"
			printf "\n<a href=\"https://github.com/%s/%s/tree/%s/\">Github Tree</a>" "${GIT_ORG}" "${repo}" "${branch}"
		} >> "${OUTDIR}"/tg.html
		TEXT=$(< "${OUTDIR}"/tg.html)
		rm -rf "${OUTDIR}"/tg.html
		curl -s "https://api.telegram.org/bot${TG_TOKEN}/sendmessage" --data "text=${TEXT}&chat_id=${CHAT_ID}&parse_mode=HTML&disable_web_page_preview=True" || printf "Telegram Notification Sending Error.\n"
	fi

elif [[ -s "${PROJECT_DIR}"/.gitlab_token ]]; then
	if [[ -s "${PROJECT_DIR}"/.gitlab_group ]]; then
		GIT_ORG=$(< "${PROJECT_DIR}"/.gitlab_group)	# Set Your Gitlab Group Name
	else
		GIT_USER="$(git config --get user.name)"
		GIT_ORG="${GIT_USER}"				# Otherwise, Your Username will be used
	fi

	# Gitlab Vars
	GITLAB_TOKEN=$(< "${PROJECT_DIR}"/.gitlab_token)	# Write Your Gitlab Token In a Text File
	if [ -f "${PROJECT_DIR}"/.gitlab_instance ]; then
		GITLAB_INSTANCE=$(< "${PROJECT_DIR}"/.gitlab_instance)
	else
		GITLAB_INSTANCE="gitlab.com"
	fi
	GITLAB_HOST="https://${GITLAB_INSTANCE}"

	# Check if already dumped or not
	[[ $(curl -sL "${GITLAB_HOST}/${GIT_ORG}/${repo}/-/raw/${branch}/all_files.txt" | grep "all_files.txt") ]] && { printf "Firmware already dumped!\nGo to https://"$GITLAB_INSTANCE"/${GIT_ORG}/${repo}/-/tree/${branch}\n" && exit 1; }

	# Remove The Journal File Inside System/Vendor
	find . -mindepth 2 -type d -name "\[SYS\]" -exec rm -rf {} \; 2>/dev/null
	split_files 62M 47M
	printf "\nFinal Repository Should Look Like...\n" && ls -lAog
	printf "\n\nStarting Git Init...\n"

	git init		# Insure Your GitLab Authorization Before Running This Script
	# Configure git for better handling of large repositories and network issues
	git config http.postBuffer 524288000		# A Simple Tuning to Get Rid of curl (18) error while `git push`
	git config http.lowSpeedLimit 0			# Disable low speed limit
	git config http.lowSpeedTime 999999		# Increase timeout
	git config pack.windowMemory 256m			# Reduce memory usage during pack
	git config pack.packSizeLimit 256m		# Limit pack file size
	git config core.compression 0				# Disable compression for speed
	
	# Validate branch name before checkout
	if [[ -z "${branch}" ]]; then
		log_error "Branch name is empty! Using incremental as fallback"
		branch="${incremental}"
	fi
	
	if [[ -z "${branch}" ]]; then
		log_fatal "Cannot determine branch name - both description and incremental are empty"
		exit 1
	fi
	
	log_info "Creating git branch: ${branch}"
	git checkout -b "${branch}" || { 
		log_warn "Failed to create branch '${branch}', trying incremental '${incremental}'"
		git checkout -b "${incremental}" && export branch="${incremental}"
	}
	
	# Verify we're on the correct branch
	current_branch=$(git rev-parse --abbrev-ref HEAD)
	if [[ "${current_branch}" != "${branch}" ]]; then
		log_warn "Current branch '${current_branch}' differs from expected '${branch}'"
		branch="${current_branch}"
	fi
	
	log_success "Git branch created: ${branch}"
	
	find . \( -name "*sensetime*" -o -name "*.lic" \) | cut -d'/' -f'2-' >| .gitignore
	[[ ! -s .gitignore ]] && rm .gitignore
	[[ -z "$(git config --get user.email)" ]] && git config user.email "guptasushrut@gmail.com"
	[[ -z "$(git config --get user.name)" ]] && git config user.name "Sushrut1101"

	# Create Subgroup
	GRP_ID=$(curl -s --request GET --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "${GITLAB_HOST}/api/v4/groups/${GIT_ORG}" | jq -r '.id')
	curl --request POST \
	--header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
	--header "Content-Type: application/json" \
	--data '{"name": "'"${brand}"'", "path": "'"$(echo ${brand} | tr [:upper:] [:lower:])"'", "visibility": "public", "parent_id": "'"${GRP_ID}"'"}' \
	"${GITLAB_HOST}/api/v4/groups/"
	echo ""

	# Subgroup ID
	get_gitlab_subgrp_id(){
		local SUBGRP=$(echo "$1" | tr '[:upper:]' '[:lower:]')
		curl -s --request GET --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "${GITLAB_HOST}/api/v4/groups/${GIT_ORG}/subgroups" | jq -r .[] | jq -r .path,.id > /tmp/subgrp.txt
		local i
		for i in $(seq "$(cat /tmp/subgrp.txt | wc -l)")
		do
			local TMP_I=$(cat /tmp/subgrp.txt | head -"$i" | tail -1)
			[[ "$TMP_I" == "$SUBGRP" ]] && cat /tmp/subgrp.txt | head -$(("$i"+1)) | tail -1 > "$2"
		done
		}

	get_gitlab_subgrp_id ${brand} /tmp/subgrp_id.txt
	SUBGRP_ID=$(< /tmp/subgrp_id.txt)

	# Create Repository
	curl -s \
	--header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
	-X POST \
	"${GITLAB_HOST}/api/v4/projects?name=${codename}&namespace_id=${SUBGRP_ID}&visibility=public"

	# Get Project/Repo ID
	get_gitlab_project_id(){
		local PROJ="$1"
		curl -s --request GET --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "${GITLAB_HOST}/api/v4/groups/$2/projects" | jq -r .[] | jq -r .path,.id > /tmp/proj.txt
		local i
		for i in $(seq "$(cat /tmp/proj.txt | wc -l)")
		do
			local TMP_I=$(cat /tmp/proj.txt | head -"$i" | tail -1)
			[[ "$TMP_I" == "$PROJ" ]] && cat /tmp/proj.txt | head -$(("$i"+1)) | tail -1 > "$3"
		done
		}
	get_gitlab_project_id ${codename} ${SUBGRP_ID} /tmp/proj_id.txt
	PROJECT_ID=$(< /tmp/proj_id.txt)

	# Delete the Temporary Files
	rm -rf /tmp/{subgrp,subgrp_id,proj,proj_id}.txt

	# Commit and Push
	# Pushing via HTTPS doesn't work on GitLab for Large Repos (it's an issue with gitlab for large repos)
	# NOTE: Your SSH Keys Needs to be Added to your Gitlab Instance
	git remote add origin git@${GITLAB_INSTANCE}:${GIT_ORG}/${repo}.git

	# Ensure that the target repo is public
	curl --request PUT --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" --url ''"${GITLAB_HOST}"'/api/v4/projects/'"${PROJECT_ID}"'' --data "visibility=public"
	printf "\n"

	# Push to GitLab
	while [[ ! $(curl -sL "${GITLAB_HOST}/${GIT_ORG}/${repo}/-/raw/${branch}/all_files.txt" | grep "all_files.txt") ]]
	do
		printf "\nPushing to %s via SSH...\nBranch:%s\n" "${GITLAB_HOST}/${GIT_ORG}/${repo}.git" "${branch}"
		sleep 1
		commit_and_push
		sleep 1
	done

	# Update the Default Branch
	curl	--request PUT \
		--header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
		--url ''"${GITLAB_HOST}"'/api/v4/projects/'"${PROJECT_ID}"'' \
		--data "default_branch=${branch}"
	printf "\n"

	# Telegram channel post
	if [[ -s "${PROJECT_DIR}"/.tg_token ]]; then
		TG_TOKEN=$(< "${PROJECT_DIR}"/.tg_token)
		if [[ -s "${PROJECT_DIR}"/.tg_chat ]]; then		# TG Channel ID
			CHAT_ID=$(< "${PROJECT_DIR}"/.tg_chat)
		else
			CHAT_ID="@DumprXDumps"
		fi
		printf "Sending telegram notification...\n"
		printf "<b>Brand: %s</b>" "${brand}" >| "${OUTDIR}"/tg.html
		{
			printf "\n<b>Device: %s</b>" "${codename}"
			printf "\n<b>Platform: %s</b>" "${platform}"
			printf "\n<b>Android Version:</b> %s" "${release}"
			[ ! -z "${kernel_version}" ] && printf "\n<b>Kernel Version:</b> %s" "${kernel_version}"
			printf "\n<b>Fingerprint:</b> %s" "${fingerprint}"
			printf "\n<a href=\"${GITLAB_HOST}/%s/%s/-/tree/%s/\">Gitlab Tree</a>" "${GIT_ORG}" "${repo}" "${branch}"
		} >> "${OUTDIR}"/tg.html
		TEXT=$(< "${OUTDIR}"/tg.html)
		rm -rf "${OUTDIR}"/tg.html
		curl -s "https://api.telegram.org/bot${TG_TOKEN}/sendmessage" --data "text=${TEXT}&chat_id=${CHAT_ID}&parse_mode=HTML&disable_web_page_preview=True" || printf "Telegram Notification Sending Error.\n"
	fi

else
	printf "Dumping done locally.\n"
	exit
fi
