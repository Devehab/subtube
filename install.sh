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
        echo -e "\n${YELLOW}Some requirements are missing.${NC}"
        exit 1
    else
        echo -e "\n${GREEN}All requirements are met!${NC}"
    fi
}

# Find an available port
find_port() {
    echo -e "\n${BOLD}Port Configuration${NC}"
    echo -e "SubTube will run on a port on your machine and map to port 5000 in the Docker container."
    
    # Check if the default port is available
    if ! check_port $DEFAULT_PORT; then
        echo -e "  ${YELLOW}!${NC} Default port $DEFAULT_PORT is already in use."
        echo -e "  ${YELLOW}→${NC} Finding an available port starting from $((DEFAULT_PORT + 1))..."
        
        # Try to find an available port
        local port=$((DEFAULT_PORT + 1))
        local max_attempts=20
        local attempt=0
        
        while [ $attempt -lt $max_attempts ]; do
            if check_port $port; then
                echo -e "  ${GREEN}✓${NC} Found available port: $port"
                echo $port > /tmp/subtube_port.txt
                return 0
            fi
            
            port=$((port + 1))
            attempt=$((attempt + 1))
        done
        
        # If we couldn't find an available port, use a default fallback
        echo -e "  ${YELLOW}!${NC} Could not find an available port. Using port 8080."
        echo "8080" > /tmp/subtube_port.txt
    else
        echo -e "  ${GREEN}✓${NC} Using default port: $DEFAULT_PORT"
        echo "$DEFAULT_PORT" > /tmp/subtube_port.txt
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
    
    # Find an available port and save it to a temporary file
    find_port
    SELECTED_PORT=$(cat /tmp/subtube_port.txt)
    rm -f /tmp/subtube_port.txt
    
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
    
    # Remove any existing compose files to avoid conflicts
    echo -e "  ${YELLOW}→${NC} Removing any existing compose files..."
    rm -f docker-compose.yml compose.yml docker-compose.yaml compose.yaml
    
    # Create a simple compose file directly
    echo -e "  ${YELLOW}→${NC} Creating docker-compose.yml file with port $SELECTED_PORT..."
    
    # Create the docker-compose.yml file
    cat > docker-compose.yml << EOL
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
      - "${SELECTED_PORT}:5000"
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
        echo -e "You can access it at ${BOLD}http://localhost:${SELECTED_PORT}${NC}"
        echo -e "\nTo stop SubTube, run: ${YELLOW}cd $install_dir && docker-compose down${NC}"
        echo -e "To start it again, run: ${YELLOW}cd $install_dir && docker-compose up -d${NC}"
    else
        echo -e "\n${RED}Failed to start SubTube. Please check the error messages above.${NC}"
        exit 1
    fi
    
    echo -e "\n${GREEN}${BOLD}Installation completed successfully!${NC}"
    echo -e "Thank you for installing SubTube!"
    echo -e "If you find this tool useful, please consider giving it a star on GitHub:"
    echo -e "${BLUE}https://github.com/Devehab/subtube${NC}\n"
}

# Run the main function
main
