#!/bin/bash

# Colors for terminal output
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

echo -e "${GREEN}SubTube Installer${NC}"
echo "============================"
echo "This script will install and run SubTube"

# Default port
PORT=3012

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if a port is in use
check_port() {
    local port=$1
    if command_exists nc; then
        nc -z localhost $port >/dev/null 2>&1
        return $?
    elif command_exists lsof; then
        lsof -i :$port >/dev/null 2>&1
        return $?
    else
        # If no tools are available, we'll find out when we try to run the container
        return 1
    fi
}

# Find an available port
find_available_port() {
    local start_port=$1
    local port=$start_port
    
    echo -e "${YELLOW}Checking if port $port is available...${NC}"
    
    while check_port $port; do
        echo -e "${YELLOW}Port $port is already in use, trying next port...${NC}"
        port=$((port + 1))
        if [ $port -gt $((start_port + 100)) ]; then
            echo -e "${RED}Failed to find an available port after checking 100 ports.${NC}"
            exit 1
        fi
    done
    
    echo -e "${GREEN}Port $port is available.${NC}"
    PORT=$port
}

# Check if Docker is installed
check_docker() {
    if command_exists docker; then
        echo -e "${GREEN}✓${NC} Docker is installed."
    else
        echo -e "${RED}✗${NC} Docker is not installed."
        install_docker
    fi
}

# Check if Docker Compose is installed
check_compose() {
    if command_exists docker-compose || (command_exists docker && docker compose version >/dev/null 2>&1); then
        echo -e "${GREEN}✓${NC} Docker Compose is installed."
    else
        echo -e "${RED}✗${NC} Docker Compose is not installed."
        install_compose
    fi
}

# Install Docker
install_docker() {
    echo -e "${YELLOW}Installing Docker...${NC}"
    
    # Detect OS
    if [ -f /etc/os-release ]; then
        # freedesktop.org and systemd
        . /etc/os-release
        OS=$NAME
    elif type lsb_release >/dev/null 2>&1; then
        # linuxbase.org
        OS=$(lsb_release -si)
    elif [ -f /etc/lsb-release ]; then
        # For some versions of Debian/Ubuntu without lsb_release command
        . /etc/lsb-release
        OS=$DISTRIB_ID
    else
        # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
        OS=$(uname -s)
    fi
    
    # Install based on OS
    case "$OS" in
        *Ubuntu*|*Debian*)
            echo "Detected Ubuntu or Debian system"
            sudo apt-get update
            sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io
            sudo systemctl enable docker
            sudo systemctl start docker
            sudo usermod -aG docker $USER
            ;;
        *Fedora*|*CentOS*|*RHEL*)
            echo "Detected Fedora/CentOS/RHEL system"
            sudo dnf -y install dnf-plugins-core
            sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            sudo dnf install -y docker-ce docker-ce-cli containerd.io
            sudo systemctl enable docker
            sudo systemctl start docker
            sudo usermod -aG docker $USER
            ;;
        *Arch*)
            echo "Detected Arch Linux system"
            sudo pacman -S docker
            sudo systemctl enable docker
            sudo systemctl start docker
            sudo usermod -aG docker $USER
            ;;
        *Darwin*)
            echo "Detected macOS system"
            echo "Please install Docker Desktop from https://www.docker.com/products/docker-desktop"
            exit 1
            ;;
        *)
            echo "Unsupported operating system: $OS"
            echo "Please install Docker manually: https://docs.docker.com/engine/install/"
            exit 1
            ;;
    esac
    
    # Check if Docker was installed correctly
    if command_exists docker; then
        echo -e "${GREEN}✓${NC} Docker installed successfully."
    else
        echo -e "${RED}✗${NC} Docker installation failed. Please install manually: https://docs.docker.com/engine/install/"
        exit 1
    fi
}

# Install Docker Compose
install_compose() {
    echo -e "${YELLOW}Installing Docker Compose...${NC}"
    
    # Check if docker compose plugin is available
    if command_exists docker && docker compose version >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Docker Compose plugin is already installed."
        return
    fi
    
    # Detect OS
    if [ "$(uname -s)" = "Darwin" ]; then
        echo "Please install Docker Desktop which includes Docker Compose"
        exit 1
    fi
    
    # Install Docker Compose plugin
    DOCKER_CONFIG=${DOCKER_CONFIG:-/usr/lib/docker/cli-plugins}
    sudo mkdir -p $DOCKER_CONFIG
    sudo curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" -o $DOCKER_CONFIG/docker-compose
    sudo chmod +x $DOCKER_CONFIG/docker-compose
    
    # Check if Docker Compose was installed correctly
    if command_exists docker-compose || (command_exists docker && docker compose version >/dev/null 2>&1); then
        echo -e "${GREEN}✓${NC} Docker Compose installed successfully."
    else
        echo -e "${RED}✗${NC} Docker Compose installation failed. Please install manually: https://docs.docker.com/compose/install/"
        exit 1
    fi
}

# Create docker-compose.yml
create_compose_file() {
    echo -e "${YELLOW}Creating docker-compose.yml file...${NC}"
    
    # Create docker-compose.yml
    cat > docker-compose.yml << EOL
version: '3.8'

services:
  subtube:
    image: devehab/subtube:latest
    container_name: subtube
    restart: unless-stopped
    ports:
      - "${PORT}:5000"  # Host port maps to container port 5000
    environment:
      - FLASK_ENV=production
      - FLASK_APP=app.py
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
EOL

    echo -e "${GREEN}✓${NC} docker-compose.yml created with port ${PORT}."
}

# Run SubTube
run_subtube() {
    echo -e "${YELLOW}Starting SubTube...${NC}"
    
    # Pull latest image
    echo "Pulling latest SubTube image..."
    docker pull devehab/subtube:latest
    
    # Stop existing container if running
    if [ "$(docker ps -q -f name=subtube)" ]; then
        echo "Stopping existing SubTube container..."
        docker stop subtube
    fi
    
    # Remove container if it exists
    if [ "$(docker ps -aq -f name=subtube)" ]; then
        echo "Removing existing SubTube container..."
        docker rm subtube
    fi
    
    # Run with docker-compose
    echo "Starting SubTube with Docker Compose..."
    if command_exists docker-compose; then
        docker-compose up -d
    else
        docker compose up -d
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} SubTube is now running!"
        echo -e "Access SubTube at: ${GREEN}http://localhost:${PORT}${NC}"
    else
        echo -e "${RED}✗${NC} Failed to start SubTube."
        exit 1
    fi
}

# Main script execution
main() {
    # Check for Docker
    check_docker
    
    # Check for Docker Compose
    check_compose
    
    # Check if default port is available, find another if not
    find_available_port $PORT
    
    # Create compose file
    create_compose_file
    
    # Run SubTube
    run_subtube
}

# Run the main function
main
