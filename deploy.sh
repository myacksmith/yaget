#!/bin/bash
set -eo pipefail

# Color codes for output formatting
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color


# Display script banner
echo -e "${BLUE}"
echo "  _____ _ _   _           _        _____                                      "
echo " / ____(_) | | |         | |      / ____|                                     "
echo "| |  __ _| |_| |     __ _| |__   | |     ___  _ __ ___  _ __   ___  ___  ___ "
echo "| | |_ | | __| |    / _\` | '_ \  | |    / _ \| '_ \` _ \| '_ \ / _ \/ __|/ _ \\"
echo "| |__| | | |_| |___| (_| | |_) | | |___| (_) | | | | | | |_) | (_) \__ \  __/"
echo " \_____|_|\__|______\__,_|_.__/   \_____\___/|_| |_| |_| .__/ \___/|___/\___|"
echo "                                                        | |                   "
echo "                                                        |_|                   "
echo -e "${NC}"
echo -e "${GREEN}GitLab Test Environment Deployer${NC}"
echo ""

# Default values
GITLAB_VERSION="latest"
# Set script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"
NETWORK_NAME=""

# Function to show usage information
# Function to display usage information
show_usage() {
  echo "Usage: $0 <deployment_name> [--version <gitlab_version>]"
  echo ""
  echo "Options:"
  echo "  --version <version>    Specify GitLab version (default: latest)"
  echo "  --help                 Show this help message"
  exit 0
}

# Function to log with timestamps
log_info() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "${BLUE}[$(timestamp)] INFO: $1${NC}"
}

log_err() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "${RED}[$(timestamp)] ERROR: $1${NC}"
}

log_warn() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "${YELLOW}[$(timestamp)] WARN: $1${NC}"
}

log_success() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "${GREEN}[$(timestamp)] SUCCESS: $1${NC}"
}

# check if dir exists
check_dir() {
    if [ ! -d "$1" ]; then
        log_err "Directory $1 does not exist."
        exit 1
    fi
}

# Parse command line args
if [ $# -lt 1 ]; then
    show_usage
fi

DEPLOYMENT_NAME="$1"
shift

while [ $# -gt 0 ]; do
    case "$1" in
        --version|-v)
            if [ -n "$2" ]; then
                GITLAB_VERSION="$2"
                shift 2
            else
                log_err "Version argument is missing."
                show_usage
            fi
            ;;
        --help|-h)
            show_usage
            ;;
        *)
            log_err "Unknown option $1."
            show_usage
            ;;
    esac
done

# Check if deploy dir exists
DEPLOYMENT_DIR="${SCRIPT_DIR}/${DEPLOYMENT_NAME}"
check_dir "${DEPLOYMENT_DIR}"

# Create a docker network for this deployment if it doesn't already exists
NETWORK_NAME="${DEPLOYMENT_NAME}-network"
if ! docker network inspect "${NETWORK_NAME}" &>/dev/null; then
    log_info "Creating Docker network: ${NETWORK_NAME}"
    docker network create "${NETWORK_NAME}"
fi

# Find all service dirs
SERVICE_DIRS=$(find "${DEPLOYMENT_DIR}" -mindept 1 -maxdepth 1 -type d | sort)

if [ -z "${SERVICE_DIRS}" ]; then
    log_err "No service directories found in ${DEPLOYMENT_DIR}"
    exit 1
fi

# function to deploy a service
deploy_service() {
    local service_dir="$1"
    local service_name=$(basename "${service_dir}")
    local service_index="$2" # Index of this service in the deployment
    local container_name="${DEPLOYMENT_NAME}-${service_name}"
    local custom_compose_file="${SCRIPT_DIR}/${DEPLOYMENT_NAME}/${service_name}/docker-compose.${service_name}.yml"
    local compose_file="${BASE_COMPOSE_FILE}"

    log_info "Deploying service: ${service_name} (index: ${service_index})"

    # Check if custom docker-compose file exists for this service
    if [ -f "${custom_compose_file}" ]; then
        log_info "Using custom docker-compose.yml file: ${custom_compose_file}"
        compose_file="${custom_compose_file}"
    else
        log_info "Using base docker-compose file: ${BASE_COMPOSE_FILE}"
    fi

    # Check if service has a config file
    if [ ! -f "${service_dir}/gitlab.rb" ]; then
        log_warn "No gitlab.rb file found for service ${service_name}"
    fi

    # Calculate port offsets based on service index
    local http_port=$((80 + service_index))
    local https_port=$((443 + service_index))
    local ssh_port=$((2222 + service_index))
    
    # Set environment variables for docker-compose
    export GITLAB_VERSION="${GITLAB_VERSION}"
    export SERVICE_NAME="${service_name}"
    export CONTAINER_NAME="${container_name}"
    export DEPLOYMENT_NAME="${DEPLOYMENT_NAME}"
    export NETWORK_NAME="${NETWORK_NAME}"
    export CONFIG_PATH="${service_dir}/gitlab.rb"
    export HTTP_PORT="${http_port}"
    export HTTPS_PORT="${https_port}"
    export SSH_PORT="${ssh_port}"

    # deploy the service using docker compose
    if [ -f "${compose_file}" ]; then
        docker compose -f "${compose_file}" -p "${DEPLOYMENT_NAME}" up -d "$service_name" || {
            log_err "Failed to deploy service ${service_name}"
            return 1
        }
        log_success "Service $service_name deployed"
    else
        log_err "Compose file ${compose_file} not found"
        return 1
    fi

    return 0
}

# Deploy each service
FAILURE=0
DEPLOYED_SERVICES=()
SERVICE_INDEX=0

for service_dir in ${SERVICE_DIRS}; do
    if deploy_service "${service_dir}" "${SERVICE_INDEX}"; then
        DEPLOYED_SERVICES+=("$(basename "${service_dir}")")
    else
        log_warn "Failed to deploy service $(basename "${service_dir}")"
        FAILURE=1
    fi
    # Increment service index for consecutive port assignment
    SERVICE_INDEX=$((SERVICE_INDEX + 1))
done

if [ ${#DEPLOYED_SERVICES[@]} -eq 0 ]; then
    log_err "No services were deployed"
    exit 1
fi

log_info "=== Deployment Summary ==="
log_info "Deployment: ${DEPLOYMENT_NAME}"
log_info "GitLab Version: ${GITLAB_VERSION}"
log_info "Docker Network: ${NETWORK_NAME}"
log_info "Deployed Services:"

for service in "${DEPLOYED_SERVICES[@]}"; do
    log_info "  - ${service} (container: ${DEPLOYMENT_NAME}-${service}, hostname: ${DEPLOYMENT_NAME}-${service}.local)"
done

if [ ${FAILURE} -eq 1 ]; then
    log_warn "Some services failed to deploy. Check the logs above for details."
fi

log_success "Deployment completed"
log_info "Note: Remember to update the /etc/hosts file with entries for each service:"
for service in "${DEPLOYED_SERVICES[@]}"; do
    log_info "  127.0.0.1       ${DEPLOYMENT_NAME}-${service}.local"
done
