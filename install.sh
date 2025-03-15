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
        return 0
    else
        echo -e "${RED}✗${NC} Docker is not installed."
        return 1
    fi
}

# Check if Docker Compose is installed
check_compose() {
    if command_exists docker-compose || (command_exists docker && docker compose version >/dev/null 2>&1); then
        echo -e "${GREEN}✓${NC} Docker Compose is installed."
        return 0
    else
        echo -e "${RED}✗${NC} Docker Compose is not installed."
        return 1
    fi
}

# Install Docker instructions
docker_install_instructions() {
    echo -e "${YELLOW}Docker installation instructions:${NC}"
    
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
    
    # Instructions based on OS
    case "$OS" in
        *Ubuntu*|*Debian*)
            echo "For Ubuntu/Debian:"
            echo "  sudo apt-get update"
            echo "  sudo apt-get install -y docker.io docker-compose"
            echo "  sudo systemctl enable --now docker"
            echo "  sudo usermod -aG docker $USER"
            echo "  newgrp docker"
            ;;
        *Fedora*|*CentOS*|*RHEL*)
            echo "For Fedora/CentOS/RHEL:"
            echo "  sudo dnf -y install dnf-plugins-core"
            echo "  sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo"
            echo "  sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin"
            echo "  sudo systemctl enable --now docker"
            echo "  sudo usermod -aG docker $USER"
            echo "  newgrp docker"
            ;;
        *Arch*)
            echo "For Arch Linux:"
            echo "  sudo pacman -S docker docker-compose"
            echo "  sudo systemctl enable --now docker"
            echo "  sudo usermod -aG docker $USER"
            echo "  newgrp docker"
            ;;
        *Darwin*)
            echo "For macOS:"
            echo "  Visit https://www.docker.com/products/docker-desktop to download and install Docker Desktop"
            ;;
        *)
            echo "For your OS, visit: https://docs.docker.com/engine/install/"
            ;;
    esac
    
    echo -e "${YELLOW}After installing Docker, run this script again.${NC}"
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

# Run SubTube with Docker
run_subtube_docker() {
    echo -e "${YELLOW}Starting SubTube with Docker...${NC}"
    
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
        echo -e "${RED}✗${NC} Failed to start SubTube with Docker."
        run_without_docker
    fi
}

# Install and run without Docker
run_without_docker() {
    echo -e "${YELLOW}Installing and running SubTube without Docker...${NC}"
    
    # Check if Python is installed
    if ! command_exists python3; then
        # On macOS, try with python command which might be Python 3
        if command_exists python && python --version 2>&1 | grep -q "Python 3"; then
            alias python3=python
        else
            echo -e "${RED}Python 3 is not installed. Please install Python 3 and try again.${NC}"
            echo "Visit https://www.python.org/downloads/ to download and install Python 3."
            exit 1
        fi
    fi
    
    # Create a temporary directory in the user's home directory for better permissions
    TEMP_DIR=$(mktemp -d "$HOME/subtube_install.XXXXXX") || TEMP_DIR="$HOME/subtube_install"
    mkdir -p "$TEMP_DIR"
    echo "Created temporary directory: $TEMP_DIR"
    cd "$TEMP_DIR" || { echo "Failed to change to temporary directory"; exit 1; }
    
    # Clone the repository
    echo "Cloning SubTube repository..."
    if command_exists git; then
        git clone https://github.com/Devehab/subtube.git
        cd subtube
    else
        echo -e "${RED}Git is not installed, downloading zip file...${NC}"
        if command_exists curl; then
            curl -L -o subtube.zip https://github.com/Devehab/subtube/archive/main.zip
            if command_exists unzip; then
                unzip subtube.zip
                cd subtube-main
            else
                echo -e "${RED}unzip is not installed. Please install unzip and try again.${NC}"
                exit 1
            fi
        else
            echo -e "${RED}curl is not installed. Please install curl and try again.${NC}"
            exit 1
        fi
    fi
    
    # Create virtual environment
    echo "Creating virtual environment..."
    python3 -m venv venv
    
    # Activate virtual environment
    echo "Activating virtual environment..."
    source venv/bin/activate
    
    # Install dependencies
    echo "Installing dependencies..."
    pip3 install -r requirements.txt
    
    # Find available port
    find_available_port $PORT
    
    # Run the application with appropriate flags for port
    echo "Starting SubTube..."
    echo -e "${GREEN}✓${NC} SubTube is now running!"
    echo -e "Access SubTube at: ${GREEN}http://localhost:${PORT}${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"
    # Determine if we should use --port or -p based on app.py
    if grep -q -- "--port" app.py; then
        python3 app.py --port $PORT
    else
        python3 app.py -p $PORT
    fi
}

# Main script execution
main() {
    # Check for Docker
    if check_docker; then
        DOCKER_AVAILABLE=1
    else
        DOCKER_AVAILABLE=0
        echo -e "${YELLOW}Docker is not installed. You can install it using the following instructions:${NC}"
        docker_install_instructions
        
        # Ask if the user wants to continue without Docker
        echo -e "${YELLOW}Do you want to continue without Docker and run SubTube directly with Python? (y/n)${NC}"
        echo -e "${GREEN}Note: This will download and run SubTube using Python directly on your computer.${NC}"
        echo -e "${GREEN}Type 'y' to continue with Python installation, or 'n' to cancel.${NC}"
        read -r answer
        if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
            echo -e "${YELLOW}Installation canceled. Please install Docker and try again.${NC}"
            exit 0
        fi
    fi
    
    # If Docker is available, also check for Docker Compose
    if [ "$DOCKER_AVAILABLE" = "1" ]; then
        if check_compose; then
            # Check if default port is available, find another if not
            find_available_port $PORT
            
            # Create compose file
            create_compose_file
            
            # Run SubTube with Docker
            run_subtube_docker
        else
            echo -e "${YELLOW}Docker Compose is not installed. Do you want to continue without Docker Compose? (y/n)${NC}"
            read -r answer
            if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
                echo -e "${YELLOW}Installation canceled. Please install Docker Compose and try again.${NC}"
                exit 0
            fi
            
            # Continue without Docker Compose
            run_without_docker
        fi
    else
        # Run without Docker
        run_without_docker
    fi
}

# Run the main function
main
