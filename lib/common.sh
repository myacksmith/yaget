#!/bin/bash
# common.sh - Shared functions for YAGET
# Provides logging and utility functions

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# Logging functions
log() {
  echo -e "$1" >&2
}

log_success() {
  echo -e "${GREEN}✓${NC} $1" >&2
}

log_warn() {
  echo -e "${YELLOW}!${NC} $1" >&2
}

log_error() {
  echo -e "${RED}✗${NC} $1" >&2
}

# Section headers
log_service() {
  local current="$1"
  local total="$2"
  local service="$2"
  echo "" >&2
  echo -e "${CYAN}[$current/$total] $service${NC}" >&2
}

# Pre/post deploy scripts markers
log_script() {
  local script_type="$1"
  echo -e "  ${PURPLE}>>>${NC} Running ${script_type}" >&2
}

# Environment source headers
log_env_source() {
  local source_file="$1"
  echo -e "    ${DIM}From $source_file:${NC}" >&2
}

# File paths (dimmed)
log_path() {
  local label="$1"
  local path="$2"
  echo -e "  $label: ${DIM}$path${NC}" >&2
}

# URLs and ports (highlighted)
log_url() {
  local url="$1"
  echo -e "  ${GREEN}✓${NC} Access: ${CYAN}$url${NC}" >&2
}

# Print all ports for a container
log_ports() {
  local ports="$1"
  if [ -n "$ports" ]; then
    echo -e "  ${GREEN}✓${NC} Ports:" >&2
    echo "$ports" | while IFS= read -r port_line; do
      # Extract container port and host port
      # Format is typically "80/tcp -> 0.0.0.0:32768"
      local parsed
      parsed=$(echo "$port_line" | awk -F '[ :/]+' '/tcp.*->/ {print $1 " " $NF}')
      if [ -n "$parsed" ]; then
        local container_port
        local host_port
        container_port=$(echo "$parsed" | cut -d ' ' -f 1)
        host_port=$(echo "$parsed" | cut -d ' ' -f 2)
        echo -e "    ${container_port} → ${CYAN}localhost:${host_port}${NC}" >&2
      else
        # Fallback for non-standard format
        echo -e "    ${DIM}${port_line}${NC}" >&2
      fi
    done
  fi
}

# Generate /etc/hosts entries for deployed services
generate_host_entries() {
  local services=("$@")
  local entries=""

  for service_info in "${services[@]}"; do
    # Format: "service:deployment-service.local"
    # Example: "gitlab:sso-gitlab.local"
    local hostname="${service_info#*:}"
    entries="${entries}127.0.0.1 ${hostname}\n"
  done

  if [ -n "$entries" ]; then
    echo ""
    echo -e "${DIM}To use Docker hostnames instead of localhost, add to /etc/hosts:${NC}"
    echo -e "${entries}"
  fi
}

# Utility functions
print_banner() {
  echo " __  __     ______     ______     ______     ______  "
  echo "/\ \_\ \   /\  __ \   /\  ___\   /\  ___\   /\__  _\ "
  echo "\ \____ \  \ \  __ \  \ \ \__ \  \ \  __\   \/_/\ \/ "
  echo " \/\_____\  \ \_\ \_\  \ \_____\  \ \_____\    \ \_\ "
  echo "  \/_____/   \/_/\/_/   \/_____/   \/_____/     \/_/ "
  echo "                                                     "
  echo "  ¯\_(ツ)_/¯ <(Yet Another GitLab Environment Tool)  "
  echo ""
}

get_script_dir() {
  # Return the SCRIPT_DIR set by the main script
  echo "${SCRIPT_DIR}"
}

get_artifacts_root() {
  echo "${YAGET_ARTIFACTS_ROOT:-${SCRIPT_DIR}/artifacts}"
}

# Environment functions
load_env_file() {
  local env_file="$1"
  
  if [ -f "${env_file}" ]; then
    # Store which varialbes came from this file
    export YAGET_ENV_SOURCE_${RANDOM}="${env_file}"

    # Read the file line by line to preserve existing variables
    while IFS='=' read -r key value; do
      # Skip comments and empty lines
      [[ "$key" =~ ^[[:space:]]*# ]] && continue
      [[ -z "$key" ]] && continue
      
      # Remove leading/trailing whitespace
      key="${key#"${key%%[![:space:]]*}"}"
      key="${key%"${key##*[![:space:]]}"}"
      
      # Only set if not already set (preserve command line overrides)
      if [ -z "${!key}" ]; then
        export "$key=$value"
        # Track where this variable cam from
        export "YAGET_SOURCE_${key}=${env_file}"
      fi
    done < "$env_file"
    
  fi
}

# Show environment variables grouped by source
show_env_by_source() {
  # Get all unique source files using env
  local source_files
  source_files=$(env | grep '^YAGET_SOURCE_' | cut -d = -f 2- | sort -u)

  # Find all unique source files
  for source_file in $source_files; do
    log_env_source "$source_file"

    # Find all variables from this source
    env | grep '^YAGET_SOURCE_' | while IFS='=' read -r key value; do
      local var_name="${key#YAGET_SOURCE_}"
      if [ "$value" = "$source_file" ]; then
        # Get the actual value of the variable
        echo -e "      ${var_name}=${!var_name}" >&2
      fi
    done
  done
}

# Error handling
die() {
  log_error "$1"
  exit 1
}
