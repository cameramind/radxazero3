#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Script Variables
LOGFILE="/var/log/docker_install.log"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="/var/backups/docker_install_${TIMESTAMP}"
REQUIRED_PACKAGES=(
    "apt-transport-https"
    "ca-certificates"
    "curl"
    "gnupg"
    "lsb-release"
    "software-properties-common"
)
DOCKER_PACKAGES=(
    "docker-ce"
    "docker-ce-cli"
    "containerd.io"
)

# Logging functions
log() {
    local level=$1
    local message=$2
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [$level] $message" | tee -a $LOGFILE
}

info() {
    log "INFO" "${GREEN}$1${NC}"
}

warn() {
    log "WARN" "${YELLOW}$1${NC}"
}

error() {
    log "ERROR" "${RED}$1${NC}"
}

debug() {
    log "DEBUG" "${BLUE}$1${NC}"
}

# System check functions
check_system() {
    info "Performing system checks..."
    
    # Check Debian version
    if [ -f /etc/debian_version ]; then
        debian_version=$(cat /etc/debian_version)
        debug "Debian version: $debian_version"
    else
        error "This is not a Debian system"
        return 1
    fi

    # Check available disk space
    disk_space=$(df -h / | awk 'NR==2 {print $4}')
    debug "Available disk space: $disk_space"
    
    # Check memory
    total_mem=$(free -h | awk '/^Mem:/ {print $2}')
    debug "Total memory: $total_mem"
    
    # Check CPU
    cpu_info=$(lscpu | grep "Model name" | cut -d ':' -f2 | xargs)
    debug "CPU: $cpu_info"
    
    return 0
}

check_network() {
    info "Checking network connectivity..."
    
    # Test DNS resolution
    if ! host -t A debian.org >/dev/null 2>&1; then
        error "DNS resolution failed"
        return 1
    fi
    
    # Test internet connectivity
    if ! ping -c 1 debian.org >/dev/null 2>&1; then
        error "Cannot ping debian.org"
        return 1
    fi
    
    debug "Network check passed"
    return 0
}

create_backup() {
    info "Creating backup directory: $BACKUP_DIR"
    mkdir -p $BACKUP_DIR

    # Backup package list
    dpkg --get-selections > "$BACKUP_DIR/packages.list"
    debug "Package list backed up"

    # Backup sources
    cp -r /etc/apt/sources.list* "$BACKUP_DIR/"
    debug "APT sources backed up"

    # Backup Docker configs if they exist
    if [ -d /etc/docker ]; then
        cp -r /etc/docker "$BACKUP_DIR/"
        debug "Docker configs backed up"
    fi
}

handle_package_installation() {
    local package=$1
    info "Installing package: $package"
    
    # Check if package is already installed
    if dpkg -l | grep -q "^ii  $package "; then
        debug "Package $package is already installed"
        return 0
    fi
    
    # Try to install package
    if apt-get install -y $package --allow-downgrades 2>>$LOGFILE; then
        debug "Successfully installed $package"
        return 0
    else
        error "Failed to install $package"
        return 1
    fi
}

remove_old_docker() {
    info "Removing old Docker installations..."
    local old_packages=(
        "docker"
        "docker-engine"
        "docker.io"
        "containerd"
        "runc"
    )
    
    for package in "${old_packages[@]}"; do
        if dpkg -l | grep -q "^ii  $package "; then
            debug "Removing $package"
            apt-get remove -y $package 2>>$LOGFILE
        else
            debug "$package is not installed"
        fi
    done
}

update_system() {
    info "Updating system packages..."
    
    # Update package lists
    if ! apt-get update 2>>$LOGFILE; then
        error "Failed to update package lists"
        return 1
    fi
    debug "Package lists updated"
    
    # Get list of upgradable packages
    local upgradable=$(apt list --upgradable 2>/dev/null | grep -v "Listing...")
    if [ ! -z "$upgradable" ]; then
        debug "Upgradable packages found:"
        echo "$upgradable" >> $LOGFILE
        
        # Attempt safe upgrade
        if ! apt-get dist-upgrade --allow-downgrades -y 2>>$LOGFILE; then
            warn "Some packages could not be upgraded"
            debug "Failed upgrade details in $LOGFILE"
        fi
    else
        debug "No packages need upgrading"
    fi
}

install_docker() {
    info "Installing Docker..."
    
    # Add GPG key
    debug "Adding Docker's GPG key"
    if [ -f /usr/share/keyrings/docker-archive-keyring.gpg ]; then
        debug "Removing old Docker GPG key"
        rm /usr/share/keyrings/docker-archive-keyring.gpg
    fi
    
    if ! curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg; then
        error "Failed to add Docker's GPG key"
        return 1
    fi
    
    # Add repository
    debug "Adding Docker repository"
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package lists
    apt-get update
    
    # Install Docker packages
    for package in "${DOCKER_PACKAGES[@]}"; do
        if ! handle_package_installation $package; then
            error "Docker installation failed"
            return 1
        fi
    done
    
    # Install Docker Compose
    debug "Installing Docker Compose"
    if ! handle_package_installation docker-compose; then
        error "Docker Compose installation failed"
        return 1
    fi
}

configure_docker() {
    info "Configuring Docker..."
    
    # Start and enable Docker service
    debug "Starting Docker service"
    systemctl start docker
    systemctl enable docker
    
    # Add current user to docker group
    if [ -n "$SUDO_USER" ]; then
        debug "Adding user $SUDO_USER to docker group"
        usermod -aG docker $SUDO_USER
    fi
}

test_docker() {
    info "Testing Docker installation..."
    
    # Check Docker version
    if docker --version >>$LOGFILE 2>&1; then
        debug "Docker version check passed"
    else
        error "Docker version check failed"
        return 1
    fi
    
    # Check Docker Compose version
    if docker-compose --version >>$LOGFILE 2>&1; then
        debug "Docker Compose version check passed"
    else
        error "Docker Compose version check failed"
        return 1
    fi
    
    # Test Docker functionality
    if docker run --rm hello-world >>$LOGFILE 2>&1; then
        debug "Docker hello-world test passed"
    else
        error "Docker hello-world test failed"
        return 1
    fi
    
    # Check Docker service status
    if systemctl is-active --quiet docker; then
        debug "Docker service is running"
    else
        error "Docker service is not running"
        return 1
    fi
}

# Main installation process
main() {
    # Initialize log file
    echo "=== Docker Installation Log - $(date) ===" > $LOGFILE
    info "Starting Docker installation process..."
    
    # Perform initial checks
    check_system || exit 1
    check_network || exit 1
    
    # Create backup
    create_backup
    
    # Installation steps
    remove_old_docker
    update_system
    install_docker
    configure_docker
    
    # Test installation
    if test_docker; then
        info "Docker installation completed successfully!"
        info "Log file is available at: $LOGFILE"
    else
        error "Docker installation failed. Check $LOGFILE for details"
        exit 1
    fi
}

# Run main function
main

# Display completion message
echo -e "\n${GREEN}Installation Summary:${NC}"
echo -e "- Log file: $LOGFILE"
echo -e "- Backup directory: $BACKUP_DIR"
echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Log out and log back in to use Docker without sudo"
echo "2. Test with: docker run hello-world"
echo -e "3. Check logs with: cat $LOGFILE\n"
