#!/bin/bash
# docker.sh - Docker-specific operations for YAGET

# Network operations
create_network() {
  local network_name="$1"
  
  if ! docker network inspect "${network_name}" &>/dev/null; then
    log "Creating Docker network: ${network_name}"
    docker network create "${network_name}"
  fi
}

remove_network() {
  local network_name="$1"
  
  if docker network inspect "${network_name}" &>/dev/null; then
    log "Removing Docker network: ${network_name}"
    docker network rm "${network_name}" || log_warn "Failed to remove network ${network_name}"
  fi
}

# Container operations
find_containers() {
  local deployment_name="$1"
  docker ps -a --filter "name=${deployment_name}-" --format "{{.Names}}"
}

stop_container() {
  local container="$1"
  
  if docker inspect "${container}" --format '{{.State.Running}}' 2>/dev/null | grep -q "true"; then
    log "Stopping container: ${container}"
    docker stop "${container}" || log_warn "Failed to stop container: ${container}"
  fi
}

remove_container() {
  local container="$1"
  
  log "Removing container: ${container}"
  docker rm "${container}" || log_warn "Failed to remove container: ${container}"
}

# Docker Compose operations
run_compose() {
  local compose_file="$1"
  local project_name="$2"
  
  docker compose -f "${compose_file}" -p "${project_name}" up -d
}

# Get container image name
get_container_image_info() {
  local container="$1"
  docker inspect "${container}" --format '{{.Config.Image}}' 2>/dev/null
}

# Port information
get_container_ports() {
  local container="$1"
  docker port "${container}" 2>/dev/null
}
