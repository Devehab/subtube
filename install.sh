#!/bin/bash

# ANSI color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'
UNDERLINE='\033[4m'

# Default port
DEFAULT_PORT=5000

# ASCII Art Logo
print_logo() {
    echo -e "${BLUE}"
    echo '   _____       __    ______      __        '
    echo '  / ___/__  __/ /_  /_  __/_  __/ /_  ____ '
    echo '  \__ \/ / / / __ \  / / / / / / __ \/ __ \'
    echo ' ___/ / /_/ / /_/ / / / / /_/ / /_/ / /_/ /'
    echo '/____/\__,_/_.___/ /_/  \__,_/_.___/\____/ '
    echo -e "${NC}"
    echo -e "${BOLD}YouTube Subtitle Downloader${NC}"
    echo -e "By ${UNDERLINE}Ehab Kahwati${NC} (https://github.com/Devehab)\n"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if a port is available
check_port() {
    local port=$1
    
    if command_exists nc; then
        nc -z localhost $port >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            return 1  # Port is in use
        else
            return 0  # Port is available
        fi
    elif command_exists lsof; then
        lsof -i :$port >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            return 1  # Port is in use
        else
            return 0  # Port is available
        fi
    else
        # If no tools are available, we'll assume the port is available
        # and let Docker handle any conflicts
        return 0
    fi
}

# Function to find an available port automatically
find_available_port() {
    local start_port=$1
    local port=$start_port
    local max_attempts=20
    local attempt=0
    
    echo -e "  ${YELLOW}→${NC} Finding an available port starting from $start_port..."
    
    while [ $attempt -lt $max_attempts ]; do
        if check_port $port; then
            echo -e "  ${GREEN}✓${NC} Found available port: $port"
            echo $port
            return 0
        fi
        
        port=$((port + 1))
        attempt=$((attempt + 1))
    done
    
    # If we couldn't find an available port, return a default port and hope for the best
    echo -e "  ${YELLOW}!${NC} Could not find an available port after $max_attempts attempts. Using port 8080."
    echo 8080
    return 1
}

# Function to get a valid port (works with curl piping)
get_port() {
    local port=$DEFAULT_PORT
    
    echo -e "\n${BOLD}Port Configuration${NC}"
    echo -e "SubTube will run on a port on your machine and map to port 5000 in the Docker container."
    
    # Check if the default port is available
    if ! check_port $DEFAULT_PORT; then
        echo -e "  ${YELLOW}!${NC} Default port $DEFAULT_PORT is already in use."
        port=$(find_available_port $((DEFAULT_PORT + 1)))
    else
        echo -e "  ${GREEN}✓${NC} Using default port: $DEFAULT_PORT"
    fi
    
    echo $port
}

# Function to display progress
show_progress() {
    local duration=$1
    local message=$2
    local elapsed=0
    local width=30
    local percentage=0
    
    echo -e "${message}"
    
    while [ $elapsed -lt $duration ]; do
        percentage=$((elapsed * 100 / duration))
        completed=$((width * percentage / 100))
        remaining=$((width - completed))
        
        progress="["
        for ((i=0; i<completed; i++)); do
            progress+="="
        done
        
        if [ $completed -lt $width ]; then
            progress+=">"
            for ((i=0; i<remaining-1; i++)); do
                progress+=" "
            done
        fi
        
        progress+="] ${percentage}%"
        
        echo -ne "\r${progress}"
        sleep 1
        ((elapsed++))
    done
    
    echo -ne "\r["
    for ((i=0; i<width; i++)); do
        echo -ne "="
    done
    echo -e "] 100%  ${GREEN}✓${NC}\n"
}

# Check system requirements
check_requirements() {
    echo -e "\n${BOLD}Checking system requirements...${NC}"
    
    local requirements_met=true
    
    # Check for Docker
    if command_exists docker; then
        echo -e "  ${GREEN}✓${NC} Docker is installed"
    else
        echo -e "  ${RED}✗${NC} Docker is not installed"
        requirements_met=false
    fi
    
    # Check for Docker Compose
    if command_exists docker-compose || command_exists "docker compose"; then
        echo -e "  ${GREEN}✓${NC} Docker Compose is installed"
    else
        echo -e "  ${RED}✗${NC} Docker Compose is not installed"
        requirements_met=false
    fi
    
    # Check for curl
    if command_exists curl; then
        echo -e "  ${GREEN}✓${NC} curl is installed"
    else
        echo -e "  ${RED}✗${NC} curl is not installed"
        requirements_met=false
    fi
    
    # Check for git
    if command_exists git; then
        echo -e "  ${GREEN}✓${NC} git is installed"
    else
        echo -e "  ${RED}✗${NC} git is not installed"
        requirements_met=false
    fi
    
    if [ "$requirements_met" = false ]; then
        echo -e "\n${YELLOW}Some requirements are missing. Installing them now...${NC}"
        install_dependencies
    else
        echo -e "\n${GREEN}All requirements are met!${NC}"
    fi
}

# Install dependencies based on OS
install_dependencies() {
    # Detect OS
    if [ "$(uname)" == "Darwin" ]; then
        # macOS
        echo -e "\n${BOLD}Installing dependencies for macOS...${NC}"
        
        # Check if Homebrew is installed
        if ! command_exists brew; then
            echo -e "  ${YELLOW}→${NC} Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        else
            echo -e "  ${GREEN}✓${NC} Homebrew is already installed"
        fi
        
        # Install Docker if not installed
        if ! command_exists docker; then
            echo -e "  ${YELLOW}→${NC} Installing Docker Desktop for Mac..."
            echo -e "${YELLOW}Please download and install Docker Desktop from https://www.docker.com/products/docker-desktop/${NC}"
            echo -e "${YELLOW}After installation, please run this script again.${NC}"
            exit 1
        fi
        
        # Install git if not installed
        if ! command_exists git; then
            echo -e "  ${YELLOW}→${NC} Installing git..."
            brew install git
        fi
        
        # Install curl if not installed
        if ! command_exists curl; then
            echo -e "  ${YELLOW}→${NC} Installing curl..."
            brew install curl
        fi
        
    elif [ -f /etc/debian_version ]; then
        # Debian/Ubuntu
        echo -e "\n${BOLD}Installing dependencies for Debian/Ubuntu...${NC}"
        
        # Update package lists
        echo -e "  ${YELLOW}→${NC} Updating package lists..."
        sudo apt-get update
        
        # Install Docker if not installed
        if ! command_exists docker; then
            echo -e "  ${YELLOW}→${NC} Installing Docker..."
            sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io
            sudo usermod -aG docker $USER
            echo -e "  ${YELLOW}→${NC} Added current user to docker group. You may need to log out and back in for this to take effect."
        fi
        
        # Install Docker Compose if not installed
        if ! command_exists docker-compose && ! command_exists "docker compose"; then
            echo -e "  ${YELLOW}→${NC} Installing Docker Compose..."
            sudo apt-get install -y docker-compose
        fi
        
        # Install git if not installed
        if ! command_exists git; then
            echo -e "  ${YELLOW}→${NC} Installing git..."
            sudo apt-get install -y git
        fi
        
        # Install curl if not installed
        if ! command_exists curl; then
            echo -e "  ${YELLOW}→${NC} Installing curl..."
            sudo apt-get install -y curl
        fi
        
    elif [ -f /etc/fedora-release ] || [ -f /etc/redhat-release ]; then
        # Fedora/RHEL/CentOS
        echo -e "\n${BOLD}Installing dependencies for Fedora/RHEL/CentOS...${NC}"
        
        # Update package lists
        echo -e "  ${YELLOW}→${NC} Updating package lists..."
        sudo dnf -y update
        
        # Install Docker if not installed
        if ! command_exists docker; then
            echo -e "  ${YELLOW}→${NC} Installing Docker..."
            sudo dnf -y install dnf-plugins-core
            sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            sudo dnf -y install docker-ce docker-ce-cli containerd.io
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker $USER
            echo -e "  ${YELLOW}→${NC} Added current user to docker group. You may need to log out and back in for this to take effect."
        fi
        
        # Install Docker Compose if not installed
        if ! command_exists docker-compose && ! command_exists "docker compose"; then
            echo -e "  ${YELLOW}→${NC} Installing Docker Compose..."
            sudo dnf -y install docker-compose
        fi
        
        # Install git if not installed
        if ! command_exists git; then
            echo -e "  ${YELLOW}→${NC} Installing git..."
            sudo dnf -y install git
        fi
        
        # Install curl if not installed
        if ! command_exists curl; then
            echo -e "  ${YELLOW}→${NC} Installing curl..."
            sudo dnf -y install curl
        fi
        
    elif [ -f /etc/arch-release ]; then
        # Arch Linux
        echo -e "\n${BOLD}Installing dependencies for Arch Linux...${NC}"
        
        # Update package lists
        echo -e "  ${YELLOW}→${NC} Updating package lists..."
        sudo pacman -Syu --noconfirm
        
        # Install Docker if not installed
        if ! command_exists docker; then
            echo -e "  ${YELLOW}→${NC} Installing Docker..."
            sudo pacman -S --noconfirm docker
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker $USER
            echo -e "  ${YELLOW}→${NC} Added current user to docker group. You may need to log out and back in for this to take effect."
        fi
        
        # Install Docker Compose if not installed
        if ! command_exists docker-compose && ! command_exists "docker compose"; then
            echo -e "  ${YELLOW}→${NC} Installing Docker Compose..."
            sudo pacman -S --noconfirm docker-compose
        fi
        
        # Install git if not installed
        if ! command_exists git; then
            echo -e "  ${YELLOW}→${NC} Installing git..."
            sudo pacman -S --noconfirm git
        fi
        
        # Install curl if not installed
        if ! command_exists curl; then
            echo -e "  ${YELLOW}→${NC} Installing curl..."
            sudo pacman -S --noconfirm curl
        fi
        
    else
        echo -e "\n${RED}Unsupported operating system. Please install Docker and Docker Compose manually.${NC}"
        exit 1
    fi
    
    echo -e "\n${GREEN}All dependencies installed successfully!${NC}"
}

# Function to create docker-compose.yml with specified port
create_compose_file() {
    local port=$1
    local install_dir=$2
    
    echo -e "  ${YELLOW}→${NC} Creating docker-compose.yml file with port $port..."
    
    cat > "$install_dir/docker-compose.yml" << EOL
version: '3.8'

services:
  subtube:
    build:
      context: .
      dockerfile: Dockerfile
    image: subtube:latest
    container_name: subtube-app
    restart: unless-stopped
    ports:
      - "${port}:5000"
    environment:
      - FLASK_ENV=production
      - FLASK_APP=app.py
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
EOL

    echo -e "  ${GREEN}✓${NC} docker-compose.yml created successfully."
}

# Function to install and run SubTube with Docker
run_with_docker() {
    local port=$1
    echo -e "\n${BOLD}Setting up SubTube with Docker...${NC}"
    
    # Create a directory for SubTube
    local install_dir="$HOME/subtube"
    mkdir -p "$install_dir"
    cd "$install_dir"
    
    # Clone the repository
    echo -e "\n${BOLD}Cloning the SubTube repository...${NC}"
    if [ -d ".git" ]; then
        echo -e "  ${YELLOW}→${NC} Repository already exists, updating..."
        git pull origin main
    else
        echo -e "  ${YELLOW}→${NC} Cloning repository..."
        git clone https://github.com/Devehab/subtube.git .
    fi
    
    # Check if Docker daemon is running
    if ! docker info > /dev/null 2>&1; then
        echo -e "\n${RED}Docker daemon is not running. Please start Docker and try again.${NC}"
        exit 1
    fi
    
    # Create docker-compose.yml with the specified port
    create_compose_file "$port" "$install_dir"
    
    # Build and run with Docker Compose
    echo -e "\n${BOLD}Building and starting SubTube with Docker...${NC}"
    
    # Check if using new or old Docker Compose command
    if command_exists "docker compose"; then
        docker compose up -d
    else
        docker-compose up -d
    fi
    
    # Check if container is running
    if [ $? -eq 0 ]; then
        echo -e "\n${GREEN}SubTube is now running!${NC}"
        echo -e "You can access it at ${BOLD}http://localhost:${port}${NC}"
        echo -e "\nTo stop SubTube, run: ${YELLOW}cd $install_dir && docker-compose down${NC}"
        echo -e "To start it again, run: ${YELLOW}cd $install_dir && docker-compose up -d${NC}"
    else
        echo -e "\n${RED}Failed to start SubTube. Please check the error messages above.${NC}"
        exit 1
    fi
}

# Main function
main() {
    clear
    print_logo
    
    echo -e "${BOLD}Welcome to the SubTube Installer!${NC}"
    echo -e "This script will install and run SubTube using Docker.\n"
    
    # Check system requirements
    check_requirements
    
    # Get port automatically (no user input required)
    PORT=$(get_port)
    
    # Show progress for downloading
    show_progress 3 "${BOLD}Preparing installation...${NC}"
    
    # Install and run with Docker
    run_with_docker "$PORT"
    
    echo -e "\n${GREEN}${BOLD}Installation completed successfully!${NC}"
    echo -e "Thank you for installing SubTube!"
    echo -e "If you find this tool useful, please consider giving it a star on GitHub:"
    echo -e "${BLUE}https://github.com/Devehab/subtube${NC}\n"
}

# Run the main function
main
