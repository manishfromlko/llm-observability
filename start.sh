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

# Function to generate random API keys
generate_api_key() {
    openssl rand -hex 16
}

# Function to check if a service is healthy
check_service_health() {
    local service_name=$1
    local url=$2
    local max_attempts=30
    local attempt=1

    print_status "Waiting for $service_name to be healthy..."

    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$url" > /dev/null 2>&1; then
            print_success "$service_name is healthy!"
            return 0
        fi

        print_status "Attempt $attempt/$max_attempts: $service_name not ready yet, waiting..."
        sleep 10
        ((attempt++))
    done

    print_error "$service_name failed to become healthy after $max_attempts attempts"
    return 1
}

# Function to check if services are already running
check_existing_services() {
    print_status "Checking for existing services..."

    local langfuse_running=false
    local litellm_running=false

    # Check if Langfuse containers are running
    if docker-compose -f langfuse/docker-compose.yml ps | grep -q "Up"; then
        langfuse_running=true
        print_warning "Langfuse services are already running"
    fi

    # Check if LiteLLM containers are running
    if docker-compose -f litellm/docker-compose.yml ps | grep -q "Up"; then
        litellm_running=true
        print_warning "LiteLLM services are already running"
    fi

    if [ "$langfuse_running" = true ] || [ "$litellm_running" = true ]; then
        echo ""
        print_warning "Some services are already running. Do you want to stop them first? (y/N)"
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            print_status "Stopping existing services..."
            ./stop.sh
        else
            print_error "Please stop existing services first with: ./stop.sh"
            exit 1
        fi
    fi
}

# Main setup function
main() {
    print_status "Starting automated Langfuse + LiteLLM setup..."

    # Check for existing services
    check_existing_services

    # Check if .env files exist, create if not
    if [ ! -f "langfuse/.env" ]; then
        print_status "Creating langfuse/.env file..."
        cp langfuse/.env.example langfuse/.env
    fi

    if [ ! -f "litellm/.env" ]; then
        print_status "Creating litellm/.env file..."
        cp litellm/.env.example litellm/.env
    fi

    # Generate API keys for Langfuse initialization
    LANGFUSE_PUBLIC_KEY="lf_pk_$(generate_api_key)"
    LANGFUSE_SECRET_KEY="lf_sk_$(generate_api_key)"

    print_status "Generated Langfuse API keys:"
    print_status "  Public Key: $LANGFUSE_PUBLIC_KEY"
    print_status "  Secret Key: $LANGFUSE_SECRET_KEY"

    # Update langfuse/.env with initialization variables
    print_status "Configuring Langfuse for headless initialization..."

    # Remove any existing LANGFUSE_INIT_* variables
    sed -i '' '/^LANGFUSE_INIT_/d' langfuse/.env

    # Add headless initialization variables
    cat >> langfuse/.env << EOF

# Headless Initialization
LANGFUSE_INIT_ORG_ID=automated-org
LANGFUSE_INIT_ORG_NAME=Automated Organization
LANGFUSE_INIT_PROJECT_ID=automated-project
LANGFUSE_INIT_PROJECT_NAME=Automated Project
LANGFUSE_INIT_PROJECT_PUBLIC_KEY=$LANGFUSE_PUBLIC_KEY
LANGFUSE_INIT_PROJECT_SECRET_KEY=$LANGFUSE_SECRET_KEY
LANGFUSE_INIT_USER_EMAIL=admin@example.com
LANGFUSE_INIT_USER_NAME=Admin User
LANGFUSE_INIT_USER_PASSWORD=admin123
EOF

    # Update litellm/.env with Langfuse credentials
    print_status "Configuring LiteLLM with Langfuse credentials..."

    # Remove existing Langfuse variables if any
    sed -i '' '/^LANGFUSE_/d' litellm/.env

    # Add Langfuse configuration
    cat >> litellm/.env << EOF

# Langfuse Integration (Callback Logging)
LANGFUSE_PUBLIC_KEY=$LANGFUSE_PUBLIC_KEY
LANGFUSE_SECRET_KEY=$LANGFUSE_SECRET_KEY
LANGFUSE_BASE_URL=http://langfuse-web:3000
EOF

    # Start Langfuse services
    print_status "Starting Langfuse services..."
    cd langfuse
    docker-compose up -d

    # Wait for Langfuse to be ready
    if ! check_service_health "Langfuse Web" "http://localhost:3000"; then
        print_error "Langfuse Web failed to start properly"
        exit 1
    fi

    if ! check_service_health "Langfuse Worker" "http://localhost:3030/api/public/health"; then
        print_error "Langfuse Worker failed to start properly"
        exit 1
    fi

    cd ..

    # Start LiteLLM services
    print_status "Starting LiteLLM services..."
    cd litellm
    docker-compose up -d

    # Wait for LiteLLM to be ready
    if ! check_service_health "LiteLLM" "http://localhost:4000/health/liveliness"; then
        print_error "LiteLLM failed to start properly"
        exit 1
    fi

    cd ..

    print_success "Setup complete!"
    echo ""
    print_success "Langfuse is available at: http://localhost:3000"
    print_success "LiteLLM is available at: http://localhost:4000"
    echo ""
    print_success "Langfuse Admin Credentials:"
    print_success "  Email: admin@example.com"
    print_success "  Password: admin123"
    echo ""
    print_success "Langfuse API Keys:"
    print_success "  Public Key: $LANGFUSE_PUBLIC_KEY"
    print_success "  Secret Key: $LANGFUSE_SECRET_KEY"
    echo ""
    print_success "You can now make requests to LiteLLM and they will be automatically traced in Langfuse!"
    echo ""
    print_status "To stop services, run: ./stop.sh"
}

# Run main function
main "$@"