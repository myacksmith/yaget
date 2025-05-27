#!/bin/bash
set -eo pipefail

# Get script directory and source libraries
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export SCRIPT_DIR  # Make it available to library functions
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/docker.sh"
source "${SCRIPT_DIR}/lib/template.sh"
source "${SCRIPT_DIR}/lib/deployment.sh"

# Print banner
print_banner

# Show usage
show_usage() {
  echo "Usage: $0 <deployment_name>"
  echo ""
  echo "Options:"
  echo "  --help                 Show this help message"
  echo ""
  echo "Environment variables:"
  echo "  GITLAB_VERSION         GitLab version (default: latest)"
  echo "  YAGET_ARTIFACTS_ROOT   Custom artifacts directory"
  echo "  YAGET_TEMPLATES_DIR    Custom templates directory (default: ./templates)"
  exit 1
}

# Parse arguments
[ $# -lt 1 ] && show_usage
DEPLOYMENT_NAME="$1"

# Handle --help
[ "$1" = "--help" ] && show_usage

# Validate deployment directory exists
TEMPLATES_DIR="${YAGET_TEMPLATES_DIR:-${SCRIPT_DIR}/templates}"
TEMPLATE_DIR="${TEMPLATES_DIR}/${DEPLOYMENT_NAME}"
[ -d "${TEMPLATE_DIR}" ] || die "Deployment ${DEPLOYMENT_NAME} not found in ${TEMPLATE_DIR}"

# Setup paths
NETWORK_NAME="${DEPLOYMENT_NAME}-network"
ARTIFACTS_ROOT="$(get_artifacts_root)"
ARTIFACTS_DIR="${ARTIFACTS_ROOT}/${DEPLOYMENT_NAME}"
DEFAULT_TEMPLATE="${SCRIPT_DIR}/docker-compose.yml.tpl"

# Create network
create_network "${NETWORK_NAME}"

# Clean and create artifacts directory
clean_artifacts "${ARTIFACTS_DIR}"
mkdir -p "${ARTIFACTS_DIR}"

# Load default environment if exists
load_env_file "${SCRIPT_DIR}/.env"

# Find and deploy services
SERVICE_DIRS=$(find_service_directories "${TEMPLATE_DIR}")
DEPLOYED_SERVICES=()

for service_dir in ${SERVICE_DIRS}; do
  SERVICE_NAME=$(basename "${service_dir}")
  SERVICE_ARTIFACTS_DIR="${ARTIFACTS_DIR}/${SERVICE_NAME}"
  
  log "Processing service: ${SERVICE_NAME}"
  
  # Load service-specific environment
  load_env_file "${service_dir}/.env"
  
  # Run pre-deploy script
  run_deployment_script "${DEPLOYMENT_NAME}" "${SERVICE_NAME}" "${service_dir}/pre-deploy.sh"
  
  # Prepare service (copy files and process templates)
  prepare_service "${service_dir}" "${ARTIFACTS_DIR}" "${SERVICE_NAME}"
  
  # Set up template variables
  export_template_variables "${DEPLOYMENT_NAME}" "${SERVICE_NAME}" "${NETWORK_NAME}" "${ARTIFACTS_DIR}" "${TEMPLATES_DIR}"
  
  # Find and process docker-compose template
  COMPOSE_TEMPLATE=$(find_compose_template "${TEMPLATE_DIR}" "${SERVICE_NAME}" "${DEFAULT_TEMPLATE}")
  COMPOSE_FILE="${SERVICE_ARTIFACTS_DIR}/docker-compose.yml"
  
  process_template "${COMPOSE_TEMPLATE}" "${COMPOSE_FILE}"
  
  # Deploy the service
  if deploy_service "${COMPOSE_FILE}" "${DEPLOYMENT_NAME}" "${SERVICE_NAME}"; then
    DEPLOYED_SERVICES+=("${SERVICE_NAME}")
    
    # Run post-deploy script
    run_deployment_script "${DEPLOYMENT_NAME}" "${SERVICE_NAME}" "${service_dir}/post-deploy.sh"
  fi
done

# Show summary
if [ ${#DEPLOYED_SERVICES[@]} -eq 0 ]; then
  log_error "No services were deployed successfully"
  exit 1
fi

show_deployment_summary "${DEPLOYMENT_NAME}" "${NETWORK_NAME}" "${DEPLOYED_SERVICES[@]}"
