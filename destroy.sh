#!/bin/bash
set -eo pipefail

# Get script directory and source libraries
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export SCRIPT_DIR  # Make it available to library functions
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

# Setup paths
NETWORK_NAME="${DEPLOYMENT_NAME}-network"
ARTIFACTS_ROOT="$(get_artifacts_root)"
# Convert to absolute path if it exists
mkdir -p "${ARTIFACTS_ROOT}" 2>/dev/null || true
ARTIFACTS_ROOT="$(cd "${ARTIFACTS_ROOT}" 2>/dev/null && pwd || echo "${ARTIFACTS_ROOT}")"
ARTIFACTS_DIR="${ARTIFACTS_ROOT}/${DEPLOYMENT_NAME}"

# Show what we're destroying
log_section "Destroying Deployment"
log "Deployment: ${DEPLOYMENT_NAME}"
log "Containers: ${DEPLOYMENT_NAME}-*"
log "Network: ${NETWORK_NAME}"

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
    log_success "Removed container: ${container}"
  done
fi

# Remove network
remove_network "${NETWORK_NAME}" && log_success "Removed network: ${NETWORK_NAME}"

# Handle artifacts directory
if [ "${KEEP_DATA}" = false ] && [ -d "${ARTIFACTS_DIR}" ]; then
  log "Removing artifacts directory: ${ARTIFACTS_DIR}"
  rm -rf "${ARTIFACTS_DIR}"
  log_success "Removed artifacts: ${ARTIFACTS_DIR}"
elif [ "${KEEP_DATA}" = true ] && [ -d "${ARTIFACTS_DIR}" ]; then
  log "Artifacts preserved: ${ARTIFACTS_DIR}"
fi

# Summary
echo ""
log_success "Deployment destroyed successfully!"
