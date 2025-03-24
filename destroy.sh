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

# Print ASCII art banner
echo " __  __     ______     ______     ______     ______  ";
echo "/\ \_\ \   /\  __ \   /\  ___\   /\  ___\   /\__  _\ ";
echo "\ \____ \  \ \  __ \  \ \ \__ \  \ \  __\   \/_/\ \/ ";
echo " \/\_____\  \ \_\ \_\  \ \_____\  \ \_____\    \ \_\ ";
echo "  \/_____/   \/_/\/_/   \/_____/   \/_____/     \/_/ ";
echo "                                                     ";
echo "    (Yet Another GitLab Environment Tool)"
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

# Get the Docker network name for this deployment
NETWORK_NAME="${DEPLOYMENT_NAME}-network"

# Find all containers belonging to this deployment
log "Finding containers for deployment: ${DEPLOYMENT_NAME}"
CONTAINERS=$(docker ps -a --filter "name=${DEPLOYMENT_NAME}-" --format "{{.Names}}")

if [ -z "${CONTAINERS}" ]; then
  log_warn "No containers found for deployment: ${DEPLOYMENT_NAME}"
else
  # Stop and remove all containers
  log "Stopping and removing containers..."
  for CONTAINER in ${CONTAINERS}; do
    log "Processing container: ${CONTAINER}"
    
    # Stop container
    if docker inspect "${CONTAINER}" --format '{{.State.Running}}' 2>/dev/null | grep -q "true"; then
      log "Stopping container: ${CONTAINER}"
      docker stop "${CONTAINER}" || log_warn "Failed to stop container: ${CONTAINER}"
    fi
    
    # Remove container
    log "Removing container: ${CONTAINER}"
    docker rm "${CONTAINER}" || log_warn "Failed to remove container: ${CONTAINER}"
  done
  log_success "All containers have been removed"
fi

# Handle volumes
if [ "${KEEP_DATA}" = false ]; then
  # Find and remove volumes for this deployment
  log "Finding volumes for deployment: ${DEPLOYMENT_NAME}"
  VOLUMES=$(docker volume ls --filter "name=${DEPLOYMENT_NAME}-" --format "{{.Name}}")
  
  if [ -z "${VOLUMES}" ]; then
    log "No volumes found for deployment: ${DEPLOYMENT_NAME}"
  else
    log "Removing volumes..."
    for VOLUME in ${VOLUMES}; do
      log "Removing volume: ${VOLUME}"
      docker volume rm "${VOLUME}" || log_warn "Failed to remove volume: ${VOLUME}"
    done
    log_success "All volumes have been removed"
  fi
else
  log "Volumes are being preserved as requested with --keep-data"
fi

# Remove network
if docker network inspect "${NETWORK_NAME}" &>/dev/null; then
  log "Removing Docker network: ${NETWORK_NAME}"
  if ! docker network rm "${NETWORK_NAME}"; then
    log_warn "Failed to remove network ${NETWORK_NAME}, it may still be in use by other containers"
  else
    log_success "Network ${NETWORK_NAME} has been removed"
  fi
else
  log "Network ${NETWORK_NAME} does not exist"
fi

# Show destruction summary
echo ""
log "=== Destruction Summary ==="
log "Deployment: ${DEPLOYMENT_NAME}"
log "Keep Data: ${KEEP_DATA}"
log_success "Destruction completed"
