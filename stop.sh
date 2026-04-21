#!/bin/bash

set -e

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Main stop function
main() {
    print_status "Stopping Langfuse + LiteLLM services..."

    # Stop LiteLLM first (depends on Langfuse)
    print_status "Stopping LiteLLM services..."
    if [ -f "litellm/docker-compose.yml" ]; then
        cd litellm
        docker compose down || print_warning "LiteLLM services may not have been running"
        cd ..
    else
        print_warning "LiteLLM docker-compose.yml not found"
    fi

    # Stop Langfuse
    print_status "Stopping Langfuse services..."
    if [ -f "langfuse/docker-compose.yml" ]; then
        cd langfuse
        docker compose down || print_warning "Langfuse services may not have been running"
        cd ..
    else
        print_warning "Langfuse docker-compose.yml not found"
    fi

    print_success "All services stopped!"
    print_status "To start services again, run: ./start.sh"
    print_status "To remove all data, run: ./stop.sh -v"
}

# Check for volume removal flag
if [ "$1" = "-v" ] || [ "$1" = "--volumes" ]; then
    print_warning "This will remove all data including databases. Are you sure? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        print_status "Stopping services and removing volumes..."

        # Stop and remove volumes for LiteLLM
        if [ -f "litellm/docker-compose.yml" ]; then
            cd litellm
            docker compose down -v || print_warning "LiteLLM services cleanup failed"
            cd ..
        fi

        # Stop and remove volumes for Langfuse
        if [ -f "langfuse/docker-compose.yml" ]; then
            cd langfuse
            docker compose down -v || print_warning "Langfuse services cleanup failed"
            cd ..
        fi

        print_success "All services stopped and data removed!"
    else
        print_status "Operation cancelled"
        exit 0
    fi
else
    main "$@"
fi