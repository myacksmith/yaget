#!/bin/bash
set -eo pipefail

# destroy.sh
# Purpose: Destroy GitLab services for a specific deployment environment
# Usage: ./destroy.sh <deployment_name> [--keep-data]
# Example: ./destroy.sh deployment1-name --keep-data

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
KEEP_DATA=false
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Function to display usage information
show_usage() {
  echo "Usage: $0 <deployment_name> [--keep-data]"
  echo ""
  echo "Options:"
  echo "  --keep-data            Preserve data volumes after destroying services"
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
echo "GitLab Test Environment Destroyer"
echo ""

# Parse command line arguments
if [ $# -lt 1 ]; then
  show_usage
fi

DEPLOYMENT_NAME="$1"
shift

while [ $# -gt 0 ]; do
  case "$1" in
    --keep-data)
      KEEP_DATA=true
      shift
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

# Get the Docker network name for this deployment
NETWORK_NAME="${DEPLOYMENT_NAME}-network"

# Find all service directories and sort them
SERVICE_DIRS=$(find "${DEPLOYMENT_DIR}" -mindepth 1 -maxdepth 1 -type d | sort)

if [ -z "${SERVICE_DIRS}" ]; then
  log_error "No service directories found in ${DEPLOYMENT_DIR}"
  exit 1
fi

# Convert to array and reverse the order for proper teardown
# Using a more compatible approach than readarray
SERVICE_DIRS_ARRAY=()
while IFS= read -r line; do
    SERVICE_DIRS_ARRAY+=("$line")
done <<< "$SERVICE_DIRS"

# Create reversed array
REVERSED_SERVICE_DIRS=()
for (( idx=${#SERVICE_DIRS_ARRAY[@]}-1 ; idx>=0 ; idx-- )) ; do
  REVERSED_SERVICE_DIRS+=("${SERVICE_DIRS_ARRAY[idx]}")
done

# Function to destroy a service
destroy_service() {
  local service_dir="$1"
  local service_name=$(basename "${service_dir}")
  local container_name="${DEPLOYMENT_NAME}-${service_name}"
  local custom_compose_file="${SCRIPT_DIR}/${DEPLOYMENT_NAME}/${service_name}/docker-compose.${service_name}.yml"
  local custom_template_file="${SCRIPT_DIR}/${DEPLOYMENT_NAME}/${service_name}/docker-compose.${service_name}.yml.template"
  local compose_file="${SCRIPT_DIR}/docker-compose.yml"
  local template_file="${SCRIPT_DIR}/docker-compose.yml.template"
  local volumes_flag=""
  
  if [ "${KEEP_DATA}" = false ]; then
    volumes_flag="-v"
    log "Destroying service: ${service_name} (including volumes)"
  else
    log "Destroying service: ${service_name} (preserving volumes)"
  fi
  
  # Check if custom compose or template file exists for this service
  if [ -f "${custom_template_file}" ]; then
    log "Using custom template file: ${custom_template_file}"
    compose_file="${custom_template_file}"
  elif [ -f "${custom_compose_file}" ]; then
    log "Using custom compose file: ${custom_compose_file}"
    compose_file="${custom_compose_file}"
  elif [ -f "${template_file}" ]; then
    log "Using base template file: ${template_file}"
    compose_file="${template_file}"
  else
    log "Using base compose file: ${compose_file}"
  fi
  
  # Set environment variables for docker compose
  export SERVICE_NAME="${service_name}"
  export CONTAINER_NAME="${container_name}"
  export DEPLOYMENT_NAME="${DEPLOYMENT_NAME}"
  export NETWORK_NAME="${NETWORK_NAME}"
  
  # First try to stop the container with docker compose
  if [ -f "${compose_file}" ]; then
    log "Stopping service ${service_name} using docker compose..."
    
    # Create a temporary compose file with environment variables expanded
    local temp_compose_file=$(mktemp)
    
    # Export variables for envsubst
    export SERVICE_NAME="${service_name}"
    export CONTAINER_NAME="${container_name}"
    export DEPLOYMENT_NAME="${DEPLOYMENT_NAME}"
    export NETWORK_NAME="${NETWORK_NAME}"
    
    # Process the compose file with envsubst if it's a template
    if [[ "${compose_file}" == *".template" ]]; then
      envsubst < "${compose_file}" > "${temp_compose_file}"
    else
      # Process regular compose file with eval for backward compatibility
      eval "cat <<EOF
$(cat "${compose_file}")
EOF" > "${temp_compose_file}"
    fi
    
    docker compose -f "${temp_compose_file}" -p "${DEPLOYMENT_NAME}" down ${volumes_flag} || {
      rm -f "${temp_compose_file}"
      log_warn "Failed to stop service ${service_name} with docker compose, trying direct Docker commands"
    }
    
    # Clean up the temporary file
    rm -f "${temp_compose_file}"
  else
    log_warn "Compose file ${compose_file} not found, falling back to direct Docker commands"
  fi
  
  # Fallback: Try to stop and remove the container directly with Docker
  if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
    log "Stopping container ${container_name}..."
    docker stop "${container_name}" || log_warn "Failed to stop container ${container_name}"
    
    log "Removing container ${container_name}..."
    docker rm "${container_name}" || log_warn "Failed to remove container ${container_name}"
  else
    log "Container ${container_name} does not exist"
  fi
  
  # Remove volumes if keep-data is not set
  if [ "${KEEP_DATA}" = false ]; then
    # List volumes for this service and remove them
    local volumes=$(docker volume ls --filter "name=${DEPLOYMENT_NAME}-${service_name}" -q)
    if [ -n "${volumes}" ]; then
      log "Removing volumes for ${service_name}..."
      for volume in ${volumes}; do
        docker volume rm "${volume}" || log_warn "Failed to remove volume ${volume}"
      done
    fi
  fi
  
  log_success "Service ${service_name} destruction completed"
}

# Destroy each service in reverse order
FAILURE=0
DESTROYED_SERVICES=()

for service_dir in "${REVERSED_SERVICE_DIRS[@]}"; do
  service_name=$(basename "${service_dir}")
  if destroy_service "${service_dir}"; then
    DESTROYED_SERVICES+=("${service_name}")
  else
    log_warn "Issues while destroying service ${service_name}"
    FAILURE=1
  fi
done

# Remove the Docker network
if docker network inspect "${NETWORK_NAME}" &>/dev/null; then
  log "Removing Docker network: ${NETWORK_NAME}"
  if ! docker network rm "${NETWORK_NAME}"; then
    log_warn "Failed to remove network ${NETWORK_NAME}, it may still be in use by other containers"
    FAILURE=1
  fi
else
  log "Network ${NETWORK_NAME} does not exist"
fi

# Show destruction summary
echo ""
log "=== Destruction Summary ==="
log "Deployment: ${DEPLOYMENT_NAME}"
log "Keep Data: ${KEEP_DATA}"
log "Destroyed Services:"

for service in "${DESTROYED_SERVICES[@]}"; do
  log "  - ${service}"
done

if [ ${FAILURE} -eq 1 ]; then
  log_warn "Some issues occurred during destruction. Check the logs above for details."
fi

log_success "Destruction completed"