#!/bin/bash

# DumprX Setup Script - Refactored with new logging system
# Installs required dependencies for DumprX

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source logging library
source "${SCRIPT_DIR}/lib/logger.sh"

# Source utilities library
source "${SCRIPT_DIR}/lib/utils.sh"

# Clear Screen
tput reset 2>/dev/null || clear

# Initialize logging
export DUMPRX_LOG_TIMESTAMP=true
export DUMPRX_LOG_COLORS=true
log_init

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

# Abort Function
function abort(){
	log_fatal "$@"
	exit 1
}

# Welcome Banner
__bannerTop

log_header "DumprX Setup - Installing Dependencies"

# Detect OS and install dependencies
log_step "Detecting operating system"

if [[ "$OSTYPE" == "linux-gnu" ]]; then

    if command -v apt > /dev/null 2>&1; then

        log_info "Ubuntu/Debian based distribution detected"
        
        log_step "Updating package repositories"
	    sudo apt -y update || abort "Failed to update apt repositories"
	    
	    log_step "Installing required packages"
        sudo apt install -y unace unrar zip unzip p7zip-full p7zip-rar sharutils rar uudeview mpack arj cabextract device-tree-compiler liblzma-dev python3-pip brotli liblz4-tool axel gawk aria2 detox cpio rename liblz4-dev jq git-lfs f2fs-tools || abort "Package installation failed"
        
        log_success "Packages installed successfully"

    elif command -v dnf > /dev/null 2>&1; then

        log_info "Fedora based distribution detected"
        
	    log_step "Installing required packages"
        sudo dnf install -y unace unrar zip unzip sharutils uudeview arj cabextract file-roller dtc python3-pip brotli axel aria2 detox cpio lz4 python3-devel xz-devel p7zip p7zip-plugins git-lfs f2fs-tools || abort "Package installation failed"
        
        log_success "Packages installed successfully"

    elif command -v pacman > /dev/null 2>&1; then

        log_info "Arch Linux based distribution detected"
        
        log_step "Updating system packages"
        sudo pacman -Syyu --needed --noconfirm >/dev/null || abort "System update failed"
        
        log_step "Installing required packages"
        sudo pacman -Sy --noconfirm unace unrar p7zip sharutils uudeview arj cabextract file-roller dtc brotli axel gawk aria2 detox cpio lz4 jq git-lfs f2fs-tools || abort "Package installation failed"
        
        log_success "Packages installed successfully"

    fi

elif [[ "$OSTYPE" == "darwin"* ]]; then

    log_info "macOS detected"
    
	log_step "Installing required packages"
    brew install protobuf xz brotli lz4 aria2 detox coreutils p7zip gawk git-lfs || abort "Package installation failed"
    
    log_success "Packages installed successfully"

fi

# Install uv for Python package management
log_step "Installing uv for Python package management"
bash -c "$(curl -sL https://astral.sh/uv/install.sh)" || abort "uv installation failed"
log_success "uv installed successfully"

# Setup complete
log_success "Setup completed successfully!"
log_info "You can now run ./dumper.sh to start using DumprX"

# Exit
exit 0
