#!/bin/bash
# Deployment script for Raspberry Pi Print Server

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on Raspberry Pi
check_raspberry_pi() {
    if [ -f /proc/device-tree/model ]; then
        MODEL=$(cat /proc/device-tree/model)
        if [[ $MODEL == *"Raspberry Pi"* ]]; then
            print_info "Detected: $MODEL"
            return 0
        fi
    fi
    print_warning "Not running on Raspberry Pi, but proceeding anyway"
    return 0
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    print_info "Docker is installed: $(docker --version)"
}

# Check if Docker Compose is available
check_docker_compose() {
    if docker compose version &> /dev/null; then
        print_info "Docker Compose is available: $(docker compose version)"
        return 0
    elif command -v docker-compose &> /dev/null; then
        print_info "Docker Compose is available: $(docker-compose --version)"
        return 0
    else
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
}

# Create .env file if it doesn't exist
setup_env_file() {
    if [ ! -f "$SCRIPT_DIR/.env" ]; then
        print_info "Creating .env file from template"
        cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
        print_warning "Please edit .env file to customize your settings"
        print_warning "Default credentials are admin/admin"
    else
        print_info ".env file already exists"
    fi
}

# Build and start containers
deploy() {
    print_info "Building Docker image..."
    docker compose -f "$SCRIPT_DIR/docker-compose.yml" build
    
    print_info "Starting containers..."
    docker compose -f "$SCRIPT_DIR/docker-compose.yml" up -d
    
    print_info "Waiting for CUPS to start..."
    sleep 5
    
    # Get the local IP address
    LOCAL_IP=$(hostname -I | awk '{print $1}')
    
    print_info "========================================"
    print_info "Print Server deployed successfully!"
    print_info "========================================"
    print_info "Access the CUPS web interface at:"
    print_info "  http://localhost:631"
    print_info "  http://$LOCAL_IP:631"
    print_info ""
    print_info "Default credentials (change in .env):"
    print_info "  Username: admin"
    print_info "  Password: admin"
    print_info "========================================"
}

# Stop containers
stop() {
    print_info "Stopping containers..."
    docker compose -f "$SCRIPT_DIR/docker-compose.yml" down
    print_info "Containers stopped"
}

# Show logs
logs() {
    docker compose -f "$SCRIPT_DIR/docker-compose.yml" logs -f
}

# Show status
status() {
    docker compose -f "$SCRIPT_DIR/docker-compose.yml" ps
}

# Main menu
show_menu() {
    echo ""
    echo "Raspberry Pi Print Server Deployment"
    echo "====================================="
    echo "1. Deploy (build and start)"
    echo "2. Stop"
    echo "3. Restart"
    echo "4. Show logs"
    echo "5. Show status"
    echo "6. Exit"
    echo ""
}

# Main script
main() {
    cd "$SCRIPT_DIR"
    
    print_info "Raspberry Pi Print Server Deployment Script"
    print_info "==========================================="
    
    check_raspberry_pi
    check_docker
    check_docker_compose
    setup_env_file
    
    if [ "$1" == "deploy" ]; then
        deploy
    elif [ "$1" == "stop" ]; then
        stop
    elif [ "$1" == "restart" ]; then
        stop
        sleep 2
        deploy
    elif [ "$1" == "logs" ]; then
        logs
    elif [ "$1" == "status" ]; then
        status
    else
        while true; do
            show_menu
            read -p "Select an option: " choice
            case $choice in
                1) deploy ;;
                2) stop ;;
                3) stop; sleep 2; deploy ;;
                4) logs ;;
                5) status ;;
                6) exit 0 ;;
                *) print_error "Invalid option" ;;
            esac
        done
    fi
}

main "$@"
