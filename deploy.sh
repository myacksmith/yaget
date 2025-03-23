#!/bin/bash
set -eo pipefail

# deploy.sh
# Purpose: Deploy GitLab services for a specific deployment environment
# Usage: ./deploy.sh <deployment_name> [--version <version>]
# Example: ./deploy.sh deployment1-name --version 15.11.3-ce.0

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
GITLAB_VERSION="latest"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_TEMPLATE_FILE="${SCRIPT_DIR}/docker-compose.yml.template"
DEFAULT_ENV_FILE="${SCRIPT_DIR}/.env"
NETWORK_NAME=""

# Function to display usage information
show_usage() {
  echo "Usage: $0 <deployment_name> [--version <gitlab_version>]"
  echo ""
  echo "Options:"
  echo "  --version <version>    Specify GitLab version (default: latest)"
  echo "  --help                 Show this help message"
  exit 1
}

# Function to log with timestamp and color
log() {
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo -e "${BLUE}[${timestamp}] INFO: $1${NC}"
}

# Function to log success messages
log_success() {
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo -e "${GREEN}[${timestamp}] SUCCESS: $1${NC}"
}

# Function to log warnings
log_warn() {
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo -e "${YELLOW}[${timestamp}] WARN: $1${NC}"
}

# Function to log errors
log_error() {
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo -e "${RED}[${timestamp}] ERROR: $1${NC}"
}

# Function to check if a directory exists
check_directory() {
  if [ ! -d "$1" ]; then
    log_error "Directory $1 does not exist."
    exit 1
  fi
}

# Print ASCII art banner
echo ""
echo "  _____ _ _   _           _        _____                                      "
echo " / ____(_) | | |         | |      / ____|                                     "
echo "| |  __ _| |_| |     __ _| |__   | |     ___  _ __ ___  _ __   ___  ___  ___ "
echo "| | |_ | | __| |    / _\` | '_ \  | |    / _ \| '_ \` _ \| '_ \ / _ \/ __|/ _ \\"
echo "| |__| | | |_| |___| (_| | |_) | | |___| (_) | | | | | | |_) | (_) \__ \  __/"
echo " \_____|_|\__|______\__,_|_.__/   \_____\___/|_| |_| |_| .__/ \___/|___/\___|"
echo "                                                        | |                   "
echo "                                                        |_|                   "
echo ""
echo "GitLab Test Environment Deployer"
echo ""

# Parse command line arguments
if [ $# -lt 1 ]; then
  show_usage
fi

DEPLOYMENT_NAME="$1"
shift

while [ $# -gt 0 ]; do
  case "$1" in
    --version)
      if [ -n "$2" ]; then
        GITLAB_VERSION="$2"
        shift 2
      else
        log_error "Version argument is missing"
        show_usage
      fi
      ;;
    --help)
      show_usage
      ;;
    *)
      log_error "Unknown option $1"
      show_usage
      ;;
  esac
done

# Check if deployment directory exists
DEPLOYMENT_DIR="${SCRIPT_DIR}/${DEPLOYMENT_NAME}"
check_directory "${DEPLOYMENT_DIR}"

# Create a Docker network for this deployment if it doesn't exist already
NETWORK_NAME="${DEPLOYMENT_NAME}-network"
if ! docker network inspect "${NETWORK_NAME}" &>/dev/null; then
  log "Creating Docker network: ${NETWORK_NAME}"
  docker network create "${NETWORK_NAME}"
fi

# Function to process the compose file using envsubst for all files
process_compose_file() {
  local source_file="$1"
  local env_file="$2"
  local service_name="$3"
  local container_name="$4"
  local service_dir="$5"
  local service_index="$6"
  
  # Create a temporary file
  local temp_file=$(mktemp)
  
  # Calculate port offsets based on service index
  # and generate a random port range to avoid collisions
  local port_base=$((10000 + (RANDOM % 5000)))
  local http_port=$((port_base + service_index))
  local https_port=$((port_base + 100 + service_index))
  local ssh_port=$((port_base + 200 + service_index))
  
  # Set variables for envsubst - export essential variables first
  set -a  # Export all variables
  
  # 1. Export essential script-defined variables first
  export SERVICE_NAME="${service_name}"
  export CONTAINER_NAME="${container_name}"
  export DEPLOYMENT_NAME="${DEPLOYMENT_NAME}"
  export NETWORK_NAME="${NETWORK_NAME}"
  export CONFIG_PATH="${service_dir}/gitlab.rb"
  export GITLAB_VERSION="${GITLAB_VERSION}"
  export SERVICE_DIR="${service_dir}"
  export HTTP_PORT="${http_port}"
  export HTTPS_PORT="${https_port}"
  export SSH_PORT="${ssh_port}"
  
  # 2. Load default environment if it exists
  if [ -f "${DEFAULT_ENV_FILE}" ]; then
    source "${DEFAULT_ENV_FILE}"
  fi
  
  # 3. Load service-specific environment file if it exists (overrides defaults)
  if [ -f "${env_file}" ]; then
    source "${env_file}"
    log "Using environment variables from ${env_file}"
  fi
  
  set +a  # Stop exporting
  
  # Process the file with envsubst
  envsubst < "${source_file}" > "${temp_file}" || {
    log_error "Failed to process file: ${source_file}"
    rm -f "${temp_file}"
    return 1
  }
  
  # Return the path to the processed file
  echo "${temp_file}"
}

# Find all service directories
SERVICE_DIRS=$(find "${DEPLOYMENT_DIR}" -mindepth 1 -maxdepth 1 -type d | sort)

if [ -z "${SERVICE_DIRS}" ]; then
  log_error "No service directories found in ${DEPLOYMENT_DIR}"
  exit 1
fi

# Function to deploy a service
deploy_service() {
  local service_dir="$1"
  local service_name=$(basename "${service_dir}")
  local service_index="$2"  # Index of this service in the deployment
  local container_name="${DEPLOYMENT_NAME}-${service_name}"
  local custom_template_file="${SCRIPT_DIR}/${DEPLOYMENT_NAME}/${service_name}/docker-compose.${service_name}.yml.template"
  local custom_compose_file="${SCRIPT_DIR}/${DEPLOYMENT_NAME}/${service_name}/docker-compose.${service_name}.yml"
  local service_env_file="${service_dir}/.env"
  local template_file="${BASE_TEMPLATE_FILE}"
  
  log "Deploying service: ${service_name} (index: ${service_index})"
  
  # Check if custom template/compose file exists for this service
  if [ -f "${custom_template_file}" ]; then
    log "Using custom template file: ${custom_template_file}"
    template_file="${custom_template_file}"
  elif [ -f "${custom_compose_file}" ]; then
    # For files without .template extension
    log "Using custom compose file: ${custom_compose_file}"
    template_file="${custom_compose_file}"
  else
    log "Using base template file: ${BASE_TEMPLATE_FILE}"
  fi
  
  # Check if service has a gitlab.rb file
  if [ ! -f "${service_dir}/gitlab.rb" ]; then
    log_warn "No gitlab.rb file found for service ${service_name}"
  fi
  
  # Process the template and get the path to the processed file
  local processed_compose_file=$(process_compose_file "${template_file}" "${service_env_file}" "${service_name}" "${container_name}" "${service_dir}" "${service_index}")
  if [ $? -ne 0 ]; then
    log_error "Failed to process template for service ${service_name}"
    return 1
  fi
  
  # Deploy the service using docker compose
  # No need for --env-file as we've already exported the variables
  if ! docker compose -f "${processed_compose_file}" -p "${DEPLOYMENT_NAME}" up -d; then
    log_error "Failed to deploy service ${service_name}"
    rm -f "${processed_compose_file}"
    return 1
  fi
  
  # Clean up the temporary file
  rm -f "${processed_compose_file}"
  log_success "Service ${service_name} deployed successfully"
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
  # Increment service index for port assignment
  SERVICE_INDEX=$((SERVICE_INDEX + 1))
done

if [ ${#DEPLOYED_SERVICES[@]} -eq 0 ]; then
  log_error "No services were deployed successfully"
  exit 1
fi

# Run post deployment scripts for each service
for service in "${DEPLOYED_SERVICES[@]}"; do
  post_deploy_script="${DEPLOYMENT_DIR}/${service}/post-deploy.sh"
  if [ -f "${post_deploy_script}" ] && [ -x "${post_deploy_script}" ]; then
    log "Running post-deployment script for ${service}..."
    "${post_deploy_script}" || {
      log_warn "Post-deployment script for ${service} returned non-zero exit code"
    }
  fi
done

# Show deployment summary
echo ""
log "=== Deployment Summary ==="
log "Deployment: ${DEPLOYMENT_NAME}"
log "GitLab Version: ${GITLAB_VERSION}"
log "Docker Network: ${NETWORK_NAME}"
log "Deployed Services:"

for service in "${DEPLOYED_SERVICES[@]}"; do
  log "  - ${service} (container: ${DEPLOYMENT_NAME}-${service}, hostname: ${DEPLOYMENT_NAME}-${service}.local)"

  # Display environment file info
  env_file="${DEPLOYMENT_DIR}/${service}/.env"
  if [ -f "${env_file}" ]; then
    log "     Environment file: ${env_file}"
  fi

  # Attempt to find the random exposed ports
  if docker port "${DEPLOYMENT_NAME}-${service}" &>/dev/null; then
    log "     Exposed Ports:"
    docker port "${DEPLOYMENT_NAME}-${service}" | while read -r port_mapping; do
      log "       $port_mapping"
    done
  fi
done

if [ ${FAILURE} -eq 1 ]; then
  log_warn "Some services failed to deploy. Check the logs above for details."
fi

log_success "Deployment completed"
echo ""
log "Remember to update your /etc/hosts file with entries for each service:"
for service in "${DEPLOYED_SERVICES[@]}"; do
  echo "  127.0.0.1    ${DEPLOYMENT_NAME}-${service}.local"
done
