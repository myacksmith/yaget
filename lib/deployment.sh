#!/bin/bash
# deployment.sh - Deployment orchestration functions for YAGET

# Clean artifacts directory for a deployment
clean_artifacts() {
  local artifacts_dir="$1"
  
  if [ -d "${artifacts_dir}" ]; then
    log "Cleaning up previous artifacts"
    rm -rf "${artifacts_dir}"
  fi
}

# Find service directories in a deployment
find_service_directories() {
  local template_dir="$1"
  find "${template_dir}" -mindepth 1 -maxdepth 1 -type d | sort
}

# Copy service files to artifacts (excluding .tpl files)
copy_service_files() {
  local source_dir="$1"
  local target_dir="$2"
  
  mkdir -p "${target_dir}"
  
  # Copy all files except .tpl files (they'll be processed separately)
  find "${source_dir}" -maxdepth 1 -type f ! -name "*.tpl" -exec cp {} "${target_dir}/" \;
  
  # Copy subdirectories as-is
  find "${source_dir}" -mindepth 1 -maxdepth 1 -type d -exec cp -r {} "${target_dir}/" \;
}

# Run deployment script if it exists
run_deployment_script() {
  local deployment_name="$1"
  local service_name="$2"
  local script_path="$3"
  
  if [ -f "${script_path}" ] && [ -x "${script_path}" ]; then
    log "Running ${script_path}"
    
    # Export useful variables for the script
    export DEPLOYMENT_NAME="${deployment_name}"
    export SERVICE_NAME="${service_name}"
    export CONTAINER_NAME="${deployment_name}-${service_name}"
    
    "${script_path}" || log_warn "Script ${script_path} returned non-zero exit code"
  fi
}

# Display deployment summary
show_deployment_summary() {
  local deployment_name="$1"
  local network_name="$2"
  local deployed_services=("${@:3}")
  
  echo ""
  log "=== Deployment Summary ==="
  log "Deployment: ${deployment_name}"
  log "Docker Network: ${network_name}"
  log "Deployed Services:"
  
  for service in "${deployed_services[@]}"; do
    local container="${deployment_name}-${service}"
    log "  - ${service} (container: ${container})"
    
    # Show exposed ports if any
    local ports=$(get_container_ports "${container}")
    if [ -n "${ports}" ]; then
      log "     Exposed Ports:"
      echo "${ports}" | while IFS= read -r port_mapping; do
        log "       ${port_mapping}"
      done
    fi
  done
  
  echo ""
  log "Artifacts directory: $(get_artifacts_root)/${deployment_name}"
  
  # Show GitLab-specific help if GitLab was deployed
  for service in "${deployed_services[@]}"; do
    if [ "${service}" = "gitlab" ]; then
      echo ""
      log "Get the root password for your GitLab instance with:"
      echo "  docker exec -it ${deployment_name}-gitlab grep 'Password: ' /etc/gitlab/initial_root_password"
      break
    fi
  done
  
  log_success "Deployment completed"
}

# Prepare a service for deployment
prepare_service() {
  local service_dir="$1"
  local artifacts_dir="$2"
  local service_name="$3"
  
  local service_artifacts_dir="${artifacts_dir}/${service_name}"
  
  # Copy all non-template files
  copy_service_files "${service_dir}" "${service_artifacts_dir}"
  
  # Process all template files
  process_template_files "${service_dir}" "${service_artifacts_dir}"
}

# Deploy a service
deploy_service() {
  local compose_file="$1"
  local project_name="$2"
  local service_name="$3"
  
  log "Deploying service: ${service_name}"
  
  if run_compose "${compose_file}" "${project_name}"; then
    log_success "Service ${service_name} deployed successfully"
    return 0
  else
    log_warn "Failed to deploy service ${service_name}"
    return 1
  fi
}