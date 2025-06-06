#!/bin/bash
# deployment.sh - Deployment orchestration functions for YAGET
# Handles service preparation, deployment, and status display

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

# Count services for progress display
count_services() {
  local template_dir="$1"
  find "${template_dir}" -mindepth 1 -maxdepth 1 -type d | wc -l
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
  local script_type="$4"  # "pre-deploy.sh" or "post-deploy.sh"
  
  if [ -f "${script_path}" ] && [ -x "${script_path}" ]; then
    log_script "${script_type}"
    
    # Export useful variables for the script
    export DEPLOYMENT_NAME="${deployment_name}"
    export SERVICE_NAME="${service_name}"
    export CONTAINER_NAME="${deployment_name}-${service_name}"
    
    # Run script in a subshell to isolate execution from parent's error handling
    # This prevents script failure from killing the entire deployment
    local exit_code
    (
      set +e # Disable errexit in subshell
      "${script_path}" 2>&1 | sed 's/^/      /'
      exit ${PIPESTATUS[0]} # Exit with script's code, not sed's
    )
    exit_code=$?

    # Handle non-zero exit codes
    if [ "$exit_code" -ne 0 ]; then
      log_warn "Script ${script_type} returned non-zero exit code: ${exit_code}"
      return "$exit_code"
    fi
  fi

  return 0
}

# Display initial configuration
show_configuration() {
  local deployment_name="$1"
  local network_name="$2"
  local template_dir="$3"
  local artifacts_dir="$4"
  
  log_section "Configuration"
  log "Deployment: ${deployment_name}"
  log "Network: ${network_name}"
  log "Templates: ${template_dir}"
  log "Artifacts: ${artifacts_dir}"
}

# Display service header with environment
show_service_header() {
  local current="$1"
  local total="$2"
  local service="$3"
  
  log_service "$current" "$total" "$service"
  
  # Show environment variables for this service
  log "  Environment:"
  show_env_by_source | sed 's/^/  /'
}

# Display deployment summary
show_deployment_summary() {
  local deployment_name="$1"
  local network_name="$2"
  local artifacts_dir="$3"
  local deployed_services=("${@:4}")
  
  log_section "Summary"
  
  if [ ${#deployed_services[@]} -eq 0 ]; then
    log_error "No services deployed!"
    return 1
  fi
  
  log_success "Deployment successful!"
  log "Services deployed: ${#deployed_services[@]}"
  log "Artifacts saved to: ${artifacts_dir}"
  
  # Generate /etc/hosts entries
  local service_hostnames=()
  for service in "${deployed_services[@]}"; do
    service_hostnames+=("${service}:${deployment_name}-${service}.local")
  done
  generate_hosts_entries "${service_hostnames[@]}"
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

# Deploy a service using docker-compose
deploy_service() {
  local compose_file="$1"
  local project_name="$2"
  local service_name="$3"
  
  # Show what we're processing (uses exported template variables)
  log "  Processing: ${TEMPLATE_DIR}/${service_name} -> ${SERVICE_DIR}"
  
  # Add spacing before docker compose output
  echo "" >&2
  
  # Run docker compose
  if run_compose "${compose_file}" "${project_name}"; then
    # Add spacing after docker compose output
    echo "" >&2
    
    # Get container info
    local image=$(get_container_image_info "${CONTAINER_NAME}")
    [ -n "$image" ] && log "  Image: ${image}"
    
    log "  Container: ${CONTAINER_NAME}"
    log "  Hostname: ${HOSTNAME}"
    log_success "Templates processed"
    log_success "Container started"
    
    # Display all ports
    local ports=$(get_container_ports "${CONTAINER_NAME}")
    [ -n "$ports" ] && log_ports "$ports"
    
    return 0
  else
    echo "" >&2  # Spacing after docker output
    log_error "Failed to deploy service ${service_name}"
    return 1
  fi
}
