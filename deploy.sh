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

# Check if envsubst is installed
if ! command -v envsubst &> /dev/null; then
  log_error "envsubst is not installed. Please install it (part of gettext package)."
  
  # Provide installation instructions based on OS
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "For Debian/Ubuntu: sudo apt-get install gettext"
    echo "For RedHat/CentOS: sudo yum install gettext"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "For MacOS: brew install gettext && brew link --force gettext"
  fi
  
  exit 1
fi

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
  local template_file="${BASE_TEMPLATE_FILE}"
  
  log "Deploying service: ${service_name} (index: ${service_index})"
  
  # Check if custom template/compose file exists for this service
  if [ -f "${custom_template_file}" ]; then
    log "Using custom template file: ${custom_template_file}"
    template_file="${custom_template_file}"
  elif [ -f "${custom_compose_file}" ]; then
    # For backward compatibility with non-template compose files
    log "Using custom compose file: ${custom_compose_file}"
    
    # Create a temporary compose file with environment variables expanded
    local temp_compose_file=$(mktemp)
    
    # Process the compose file and expand variables
    eval "cat <<EOF
$(cat "${custom_compose_file}")
EOF" > "${temp_compose_file}"
    
    # Use the processed compose file
    docker compose -f "${temp_compose_file}" -p "${DEPLOYMENT_NAME}" up -d || {
      rm -f "${temp_compose_file}"
      log_error "Failed to deploy service ${service_name}"
      return 1
    }
    
    # Clean up the temporary file
    rm -f "${temp_compose_file}"
    
    log_success "Service ${service_name} deployed successfully"
    return 0
  else
    log "Using base template file: ${BASE_TEMPLATE_FILE}"
  fi
  
  # Check if service has a gitlab.rb file
  if [ ! -f "${service_dir}/gitlab.rb" ]; then
    log_warn "No gitlab.rb file found for service ${service_name}"
  fi
  
  # Calculate port offsets based on service index
  local http_port=$((80 + service_index))
  local https_port=$((443 + service_index))
  local ssh_port=$((2222 + service_index))
  
  # Create a temporary compose file with rendered template
  local temp_compose_file=$(mktemp)
  
  # Export all variables needed for envsubst
  export SERVICE_NAME="${service_name}"
  export GITLAB_VERSION="${GITLAB_VERSION}"
  export CONTAINER_NAME="${container_name}"
  export DEPLOYMENT_NAME="${DEPLOYMENT_NAME}"
  export NETWORK_NAME="${NETWORK_NAME}"
  export CONFIG_PATH="${service_dir}/gitlab.rb"
  export HTTP_PORT="${http_port}"
  export HTTPS_PORT="${https_port}"
  export SSH_PORT="${ssh_port}"
  
  # Render the template using envsubst
  envsubst < "${template_file}" > "${temp_compose_file}" || {
    rm -f "${temp_compose_file}"
    log_error "Failed to render template"
    return 1
  }
  
  # Deploy the service using docker compose
  if [ -s "${temp_compose_file}" ]; then
    docker compose -f "${temp_compose_file}" -p "${DEPLOYMENT_NAME}" up -d || {
      rm -f "${temp_compose_file}"
      log_error "Failed to deploy service ${service_name}"
      return 1
    }
    
    # Clean up the temporary file
    rm -f "${temp_compose_file}"
    
    log_success "Service ${service_name} deployed successfully"
  else
    rm -f "${temp_compose_file}"
    log_error "Generated compose file is empty"
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
  # Increment service index for port assignment
  SERVICE_INDEX=$((SERVICE_INDEX + 1))
done

if [ ${#DEPLOYED_SERVICES[@]} -eq 0 ]; then
  log_error "No services were deployed successfully"
  exit 1
fi

# Show deployment summary
echo ""
log "=== Deployment Summary ==="
log "Deployment: ${DEPLOYMENT_NAME}"
log "GitLab Version: ${GITLAB_VERSION}"
log "Docker Network: ${NETWORK_NAME}"
log "Deployed Services:"

for service in "${DEPLOYED_SERVICES[@]}"; do
  log "  - ${service} (container: ${DEPLOYMENT_NAME}-${service}, hostname: ${DEPLOYMENT_NAME}-${service}.local)"
done

if [ ${FAILURE} -eq 1 ]; then
  log_warn "Some services failed to deploy. Check the logs above for details."
fi

log_success "Deployment completed"
echo ""
log "Remember to manually update your /etc/hosts file with entries for each service:"
for service in "${DEPLOYED_SERVICES[@]}"; do
  echo "  127.0.0.1    ${DEPLOYMENT_NAME}-${service}.local"
done
