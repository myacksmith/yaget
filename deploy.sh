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
  echo "  Any variables used in your templates can be set via:"
  echo "  - .env files in template directories"
  echo "  - Command line: VAR=value $0 <deployment>"
  echo ""
  echo "Special variables:"
  echo "  YAGET_ARTIFACTS_ROOT   Custom artifacts directory (default: ./artifacts)"
  echo "  YAGET_TEMPLATES_DIR    Custom templates directory (default: ./templates)"
  echo ""
  echo "Examples:"
  echo "  $0 basic"
  echo "  GITLAB_VERSION=16.0.0 $0 basic"
  echo "  YAGET_TEMPLATES_DIR=/shared/templates $0 custom"
  exit 1
}

# Parse arguments
[ $# -lt 1 ] && show_usage
DEPLOYMENT_NAME="$1"

# Handle --help
[ "$1" = "--help" ] && show_usage

# Validate deployment directory exists
TEMPLATES_DIR="${YAGET_TEMPLATES_DIR:-${SCRIPT_DIR}/templates}"
TEMPLATES_DIR="$(cd "${TEMPLATES_DIR}" 2>/dev/null && pwd)" || die "Templates directory not found: ${TEMPLATES_DIR}"
TEMPLATE_DIR="${TEMPLATES_DIR}/${DEPLOYMENT_NAME}"
[ -d "${TEMPLATE_DIR}" ] || die "Deployment ${DEPLOYMENT_NAME} not found in ${TEMPLATES_DIR}"

# Setup paths (convert to absolute)
NETWORK_NAME="${DEPLOYMENT_NAME}-network"
ARTIFACTS_ROOT="$(get_artifacts_root)"
mkdir -p "${ARTIFACTS_ROOT}"
ARTIFACTS_ROOT="$(cd "${ARTIFACTS_ROOT}" && pwd)"
ARTIFACTS_DIR="${ARTIFACTS_ROOT}/${DEPLOYMENT_NAME}"
DEFAULT_TEMPLATE="${SCRIPT_DIR}/docker-compose.yml.tpl"

# Load default environment if exists
log "Loading environment:"
[ -f "${SCRIPT_DIR}/.env" ] && log_success "${SCRIPT_DIR}/.env" && load_env_file "${SCRIPT_DIR}/.env"

# Show initial configuration
show_configuration "${DEPLOYMENT_NAME}" "${NETWORK_NAME}" "${TEMPLATE_DIR}" "${ARTIFACTS_DIR}"

# Create network
create_network "${NETWORK_NAME}"

# Clean and create artifacts directory
clean_artifacts "${ARTIFACTS_DIR}"
mkdir -p "${ARTIFACTS_DIR}"

# Find and deploy services
log_section "Deploying Services"
SERVICE_DIRS=$(find_service_directories "${TEMPLATE_DIR}")
SERVICE_COUNT=$(count_services "${TEMPLATE_DIR}")
CURRENT_STEP=0
DEPLOYED_SERVICES=()

for service_dir in ${SERVICE_DIRS}; do
  SERVICE_NAME=$(basename "${service_dir}")
  SERVICE_ARTIFACTS_DIR="${ARTIFACTS_DIR}/${SERVICE_NAME}"
  CURRENT_STEP=$((CURRENT_STEP + 1))
  
  # Load service-specific environment
  [ -f "${service_dir}/.env" ] && log_success "${service_dir}/.env" && load_env_file "${service_dir}/.env"
  
  # Set up template variables BEFORE showing service header
  # This ensures HOSTNAME etc. are set correctly
  export_template_variables "${DEPLOYMENT_NAME}" "${SERVICE_NAME}" "${NETWORK_NAME}" "${ARTIFACTS_DIR}" "${TEMPLATES_DIR}"
  
  # Show service header with environment
  show_service_header "${CURRENT_STEP}" "${SERVICE_COUNT}" "${SERVICE_NAME}"
  
  # Run pre-deploy script
  if ! run_deployment_script "${DEPLOYMENT_NAME}" "${SERVICE_NAME}" "${service_dir}/pre-deploy.sh" "pre-deploy.sh"; then
    log_error "Pre-deploy script failed for ${SERVICE_NAME}. Skipping service deployment"
    continue
  fi
  
  # Prepare service (copy files and process templates)
  prepare_service "${service_dir}" "${ARTIFACTS_DIR}" "${SERVICE_NAME}"
  
  # Find and process docker-compose template
  COMPOSE_TEMPLATE=$(find_compose_template "${TEMPLATE_DIR}" "${SERVICE_NAME}" "${DEFAULT_TEMPLATE}")
  COMPOSE_FILE="${SERVICE_ARTIFACTS_DIR}/docker-compose.yml"
  
  process_template "${COMPOSE_TEMPLATE}" "${COMPOSE_FILE}"
  
  # Deploy the service (uses exported variables)
  if deploy_service "${COMPOSE_FILE}" "${DEPLOYMENT_NAME}" "${SERVICE_NAME}"; then
    DEPLOYED_SERVICES+=("${SERVICE_NAME}")
    
    # Run post-deploy script
    run_deployment_script "${DEPLOYMENT_NAME}" "${SERVICE_NAME}" "${service_dir}/post-deploy.sh" "post-deploy.sh"
  else
    log_error "Failed to deploy ${SERVICE_NAME}, continuing with other services..."
  fi
done

# Show summary
show_deployment_summary "${DEPLOYMENT_NAME}" "${NETWORK_NAME}" "${ARTIFACTS_DIR}" "${DEPLOYED_SERVICES[@]}"
