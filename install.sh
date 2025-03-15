#!/bin/bash

# Colors for terminal output
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

# Default port
PORT=3012
AUTO_MODE=true  # Always run in automatic mode
BACKGROUND=true # Run in background

echo -e "${GREEN}SubTube Installer${NC}"
echo "============================"
echo "This script will install and run SubTube"

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

# Display Docker installation instructions but don't wait
docker_install_instructions() {
    echo -e "${YELLOW}Docker is not installed. Here are Docker installation instructions for your reference:${NC}"
    
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
            ;;
        *Fedora*|*CentOS*|*RHEL*)
            echo "For Fedora/CentOS/RHEL:"
            echo "  sudo dnf install -y docker docker-compose"
            ;;
        *Arch*)
            echo "For Arch Linux:"
            echo "  sudo pacman -S docker docker-compose"
            ;;
        *Darwin*)
            echo "For macOS:"
            echo "  Visit https://www.docker.com/products/docker-desktop to download and install Docker Desktop"
            ;;
        *)
            echo "For your OS, visit: https://docs.docker.com/engine/install/"
            ;;
    esac
    
    echo -e "${YELLOW}Proceeding with direct Python installation...${NC}"
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
        return 0
    else
        echo -e "${RED}✗${NC} Failed to start SubTube with Docker."
        return 1
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
    INSTALL_DIR="$HOME/subtube_app"
    mkdir -p "$INSTALL_DIR"
    echo "Created installation directory: $INSTALL_DIR"
    cd "$INSTALL_DIR" || { echo "Failed to change to installation directory"; exit 1; }
    
    # Clone the repository
    echo "Cloning SubTube repository..."
    if command_exists git; then
        git clone https://github.com/Devehab/subtube.git .
        if [ $? -ne 0 ]; then
            # If directory not empty, try to pull instead
            if [ "$(ls -A $INSTALL_DIR)" ]; then
                echo "Directory not empty, pulling latest changes instead..."
                git pull
            else
                echo -e "${RED}Failed to clone repository.${NC}"
                exit 1
            fi
        fi
    else
        echo -e "${YELLOW}Git is not installed, downloading zip file...${NC}"
        if command_exists curl; then
            curl -L -o subtube.zip https://github.com/Devehab/subtube/archive/main.zip
            if command_exists unzip; then
                unzip -o subtube.zip
                # Move all files from the subdirectory up one level
                mv subtube-main/* .
                rm -rf subtube-main
                rm subtube.zip
            else
                echo -e "${RED}unzip is not installed. Please install unzip and try again.${NC}"
                exit 1
            fi
        else
            echo -e "${RED}curl is not installed. Please install curl and try again.${NC}"
            exit 1
        fi
    fi
    
    # Create virtual environment if it doesn't exist
    if [ ! -d "venv" ]; then
        echo "Creating virtual environment..."
        python3 -m venv venv
    else
        echo "Virtual environment already exists."
    fi
    
    # Activate virtual environment
    echo "Activating virtual environment..."
    source venv/bin/activate
    
    # Install dependencies
    echo "Installing dependencies..."
    pip3 install -r requirements.txt
    
    # Find available port
    find_available_port $PORT
    
    # Run the application in background if requested
    echo "Starting SubTube..."
    
    # Verify app.py exists
    if [ ! -f "app.py" ]; then
        echo -e "${RED}Error: app.py not found in the current directory!${NC}"
        echo "Contents of the current directory:"
        ls -la
        echo -e "${YELLOW}Trying to find app.py in subdirectories...${NC}"
        find . -name "app.py" -type f
        
        # Look for app.py in subdirectories and if found, change to that directory
        APP_PATH=$(find . -name "app.py" -type f | head -1)
        if [ -n "$APP_PATH" ]; then
            APP_DIR=$(dirname "$APP_PATH")
            echo -e "${GREEN}Found app.py in $APP_DIR, changing to that directory.${NC}"
            cd "$APP_DIR" || { echo "Failed to change to directory with app.py"; exit 1; }
        else
            echo -e "${RED}Cannot find app.py in any subdirectory. Installation failed.${NC}"
            exit 1
        fi
    fi
    
    # Check requirements.txt exists
    if [ ! -f "requirements.txt" ]; then
        echo -e "${RED}Warning: requirements.txt not found!${NC}"
        echo "Creating basic requirements.txt file..."
        echo "flask==2.0.1
requests==2.26.0
youtube_transcript_api==0.4.4" > requirements.txt
    fi
    
    # Create a script to run the app and handle stopping
    cat > run_subtube.sh << EOL
#!/bin/bash
cd "$(pwd)"
source venv/bin/activate

# Check if Flask is installed
if ! python3 -c "import flask" 2>/dev/null; then
    echo "Installing Flask..."
    pip3 install flask requests youtube_transcript_api
fi

# Determine which port flag to use
if grep -q -- "--port" app.py; then
    python3 app.py --port $PORT
elif grep -q -- "-p" app.py; then
    python3 app.py -p $PORT
else
    # If we can't determine which flag to use, try both
    echo "Trying to run with --port flag..."
    python3 app.py --port $PORT || python3 app.py -p $PORT
fi
EOL
    chmod +x run_subtube.sh
    
    # Create a verification script to check if the app is running
    cat > verify_subtube.sh << EOL
#!/bin/bash
PORT=$PORT
MAX_ATTEMPTS=30
ATTEMPT=0

echo "Verifying SubTube is running on http://localhost:$PORT..."

while [ \$ATTEMPT -lt \$MAX_ATTEMPTS ]; do
    ATTEMPT=\$((ATTEMPT+1))
    echo "Checking connection (attempt \$ATTEMPT of \$MAX_ATTEMPTS)..."
    
    if command -v curl >/dev/null 2>&1; then
        RESPONSE=\$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT)
        if [ "\$RESPONSE" = "200" ] || [ "\$RESPONSE" = "302" ]; then
            echo "✅ Connection successful! SubTube is running."
            exit 0
        fi
    elif command -v wget >/dev/null 2>&1; then
        if wget -q --spider http://localhost:$PORT; then
            echo "✅ Connection successful! SubTube is running."
            exit 0
        fi
    elif command -v nc >/dev/null 2>&1; then
        if nc -z localhost $PORT; then
            echo "✅ Port $PORT is open. SubTube appears to be running."
            exit 0
        fi
    else
        echo "No tools available to check connection. Please verify manually."
        exit 1
    fi
    
    sleep 1
done

echo "❌ Failed to verify SubTube is running after \$MAX_ATTEMPTS attempts."
echo "Please check logs at $(pwd)/subtube.log"
exit 1
EOL
    chmod +x verify_subtube.sh
    
    if [ "$BACKGROUND" = true ]; then
        echo -e "${YELLOW}Running in background. To stop SubTube, run: pkill -f 'python.*app.py'${NC}"
        nohup ./run_subtube.sh > subtube.log 2>&1 &
        APP_PID=$!
        echo $APP_PID > subtube.pid
        echo -e "${GREEN}SubTube is starting in the background with PID $APP_PID${NC}"
        echo -e "${YELLOW}View logs at: $(pwd)/subtube.log${NC}"
        
        # Verify the app is running
        ./verify_subtube.sh
        if [ $? -ne 0 ]; then
            echo -e "${RED}Warning: Could not verify SubTube is running properly.${NC}"
            echo -e "Please check the logs at: ${YELLOW}$(pwd)/subtube.log${NC}"
            echo -e "Try opening: ${GREEN}http://localhost:${PORT}${NC} in your browser"
            echo -e "If the site doesn't load, try running the app manually:"
            echo -e "${YELLOW}cd $(pwd) && source venv/bin/activate && python3 app.py -p ${PORT}${NC}"
        else
            echo -e "${GREEN}✓${NC} SubTube is now running!"
            echo -e "Access SubTube at: ${GREEN}http://localhost:${PORT}${NC}"
        fi
    else
        echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"
        ./run_subtube.sh
    fi
}

# Main script execution - automatic mode
main() {
    # Find available port
    find_available_port $PORT
    
    # Check for Docker
    if command_exists docker && (command_exists docker-compose || (command_exists docker && docker compose version >/dev/null 2>&1)); then
        echo -e "${GREEN}Docker and Docker Compose are installed. Using Docker installation method.${NC}"
        # Create compose file
        create_compose_file
        # Run SubTube with Docker
        if ! run_subtube_docker; then
            echo -e "${YELLOW}Docker installation failed. Falling back to direct Python installation.${NC}"
            run_without_docker
        fi
    else
        # Docker not available, show instructions but proceed with Python
        if ! command_exists docker; then
            docker_install_instructions
        elif ! command_exists docker-compose && ! (command_exists docker && docker compose version >/dev/null 2>&1); then
            echo -e "${YELLOW}Docker Compose is not installed. Proceeding with direct Python installation.${NC}"
        fi
        # Run without Docker
        run_without_docker
    fi
}

# Run the main function
main
