#!/bin/bash
# template.sh - Template processing functions for YAGET

# Export standard template variables
export_template_variables() {
  local deployment_name="$1"
  local service_name="$2"
  local network_name="$3"
  local artifacts_dir="$4"
  local templates_dir="$5"
  
  export DEPLOYMENT_NAME="${deployment_name}"
  export SERVICE_NAME="${service_name}"
  export CONTAINER_NAME="${deployment_name}-${service_name}"
  export NETWORK_NAME="${network_name}"
  export SERVICE_DIR="${artifacts_dir}/${service_name}"
  export CONFIG_PATH="${artifacts_dir}/${service_name}"  # Alias for SERVICE_DIR
  export TEMPLATE_DIR="${templates_dir}/${deployment_name}"
  export HOSTNAME="${deployment_name}-${service_name}.local"
}

# Process a template file
process_template() {
  local template_file="$1"
  local output_file="$2"
  
  envsubst < "${template_file}" > "${output_file}" || \
    log_error "Failed to process template: ${template_file}"
}

# Process all .tpl files in a directory
process_template_files() {
  local source_dir="$1"
  local target_dir="$2"
  
  while IFS= read -r -d '' template_file; do
    local relative_path="${template_file#$source_dir/}"
    local output_file="${target_dir}/${relative_path%.tpl}"
    
    # Create subdirectories if needed
    local output_dir="$(dirname "${output_file}")"
    [ -d "${output_dir}" ] || mkdir -p "${output_dir}"
    
    process_template "${template_file}" "${output_file}"
  done < <(find "${source_dir}" -name "*.tpl" -type f -print0)
}

# Find the docker-compose template for a service
find_compose_template() {
  local template_dir="$1"
  local service_name="$2"
  local default_template="$3"
  
  # Check for custom template
  local custom_template="${template_dir}/${service_name}/docker-compose.yml.tpl"
  
  if [ -f "${custom_template}" ]; then
    echo "${custom_template}"
  else
    echo "${default_template}"
  fi
}