#!/bin/bash

# Docker Installation Script for Ubuntu/Debian
# This script installs Docker and Docker Compose

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Docker Installation Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    echo -e "${GREEN}Docker is already installed!${NC}"
    docker --version
    exit 0
fi

# Check for sudo access
if ! sudo -n true 2>/dev/null; then
    echo -e "${YELLOW}This script requires sudo access.${NC}"
    echo "Please run with: sudo bash install-docker.sh"
    exit 1
fi

echo -e "${GREEN}Installing Docker...${NC}"
echo ""

# Update package index
echo "Updating package index..."
sudo apt-get update -qq

# Install prerequisites
echo "Installing prerequisites..."
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
echo "Adding Docker GPG key..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up repository
echo "Setting up Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
echo "Installing Docker Engine..."
sudo apt-get update -qq
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker service
echo "Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to docker group
echo "Adding user to docker group..."
sudo usermod -aG docker $USER

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Docker installed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Verify installation
echo "Verifying installation..."
docker --version
docker compose version

echo ""
echo -e "${YELLOW}Note: You may need to log out and back in for group changes to take effect.${NC}"
echo -e "${YELLOW}Or run: newgrp docker${NC}"
echo ""
echo -e "${GREEN}You can now run: ./docker-start.sh${NC}"
