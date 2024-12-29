#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function for logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    error "Please run as root"
    exit 1
fi

# Function to check command status
check_status() {
    if [ $? -eq 0 ]; then
        log "$1 - OK"
    else
        error "$1 - FAILED"
        exit 1
    fi
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Remove old versions
log "Removing old Docker versions if they exist..."
apt remove -y docker docker-engine docker.io containerd runc >/dev/null 2>&1

# Update system
log "Updating system packages..."
apt update
check_status "System update"
apt upgrade -y
check_status "System upgrade"

# Install prerequisites
log "Installing prerequisites..."
apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common
check_status "Prerequisites installation"

# Add Docker's official GPG key
log "Adding Docker's GPG key..."
if [ -f /usr/share/keyrings/docker-archive-keyring.gpg ]; then
    warning "Docker GPG key already exists. Removing old key..."
    rm /usr/share/keyrings/docker-archive-keyring.gpg
fi

curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
check_status "GPG key installation"

# Add Docker repository
log "Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
check_status "Repository addition"

# Update apt after adding Docker repository
log "Updating package lists..."
apt update
check_status "Package lists update"

# Install Docker
log "Installing Docker..."
apt install -y docker-ce docker-ce-cli containerd.io
check_status "Docker installation"

# Install Docker Compose
log "Installing Docker Compose..."
apt install -y docker-compose
check_status "Docker Compose installation"

# Start and enable Docker service
log "Starting Docker service..."
systemctl start docker
check_status "Docker service start"

log "Enabling Docker service..."
systemctl enable docker
check_status "Docker service enable"

# Add current user to docker group
if [ -n "$SUDO_USER" ]; then
    log "Adding user $SUDO_USER to docker group..."
    usermod -aG docker $SUDO_USER
    check_status "User addition to docker group"
fi

# Install additional development packages
log "Installing additional development packages..."
apt install -y \
    git \
    python3-pip \
    python3-venv \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3-dev
check_status "Development packages installation"

# Verify installations
log "Verifying installations..."
docker_version=$(docker --version)
compose_version=$(docker-compose --version)
python_version=$(python3 --version)
pip_version=$(pip3 --version)

echo -e "\nInstalled versions:"
echo "Docker: $docker_version"
echo "Docker Compose: $compose_version"
echo "Python: $python_version"
echo "Pip: $pip_version"

# Test Docker installation
log "Testing Docker installation..."
if docker run hello-world >/dev/null 2>&1; then
    log "Docker test successful!"
else
    error "Docker test failed. Please check the installation."
fi

# Final instructions
echo -e "\n${GREEN}Installation completed successfully!${NC}"
if [ -n "$SUDO_USER" ]; then
    echo -e "${YELLOW}Please log out and log back in for docker group changes to take effect.${NC}"
fi

echo -e "\nYou can verify the installation with these commands:"
echo "docker --version"
echo "docker-compose --version"
echo "docker run hello-world"
