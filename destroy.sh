#!/bin/bash
set -eo pipefail

# Get script directory and source libraries
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/docker.sh"

# Print banner
print_banner

# Default values
KEEP_DATA=false

# Show usage
show_usage() {
  echo "Usage: $0 <deployment_name> [options]"
  echo ""
  echo "Options:"
  echo "  --keep-data            Preserve artifacts directory (including all data)"
  echo "  --help                 Show this help message"
  exit 1
}

# Parse arguments
[ $# -lt 1 ] && show_usage

DEPLOYMENT_NAME="$1"
shift

# Parse options
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
      log_error "Unknown option: $1"
      show_usage
      ;;
  esac
done

# Get network name
NETWORK_NAME="${DEPLOYMENT_NAME}-network"

# Find and stop all containers
log "Finding containers for deployment: ${DEPLOYMENT_NAME}"
CONTAINERS=$(find_containers "${DEPLOYMENT_NAME}")

if [ -z "${CONTAINERS}" ]; then
  log_warn "No containers found for deployment: ${DEPLOYMENT_NAME}"
else
  # Stop and remove containers
  log "Stopping and removing containers..."
  for container in ${CONTAINERS}; do
    stop_container "${container}"
    remove_container "${container}"
  done
  log_success "All containers have been removed"
fi

# Remove network
remove_network "${NETWORK_NAME}"

# Handle artifacts directory
ARTIFACTS_ROOT="$(get_artifacts_root)"
ARTIFACTS_DIR="${ARTIFACTS_ROOT}/${DEPLOYMENT_NAME}"

if [ "${KEEP_DATA}" = false ] && [ -d "${ARTIFACTS_DIR}" ]; then
  log "Removing artifacts directory: ${ARTIFACTS_DIR}"
  rm -rf "${ARTIFACTS_DIR}"
  log_success "Artifacts directory has been removed"
elif [ "${KEEP_DATA}" = true ] && [ -d "${ARTIFACTS_DIR}" ]; then
  log "Artifacts directory preserved: ${ARTIFACTS_DIR}"
fi

# Show summary
echo ""
log "=== Destruction Summary ==="
log "Deployment: ${DEPLOYMENT_NAME}"
log "Keep Data: ${KEEP_DATA}"
log_success "Destruction completed"