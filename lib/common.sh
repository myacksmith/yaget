#!/bin/bash
# common.sh - Shared functions for YAGET
# Provides logging, environment management, and utility functions

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

# Basic logging functions
log() {
  local message="$1"
  
  # Special case for "Processing: source -> dest"
  if [[ "$message" =~ ^([[:space:]]*)Processing:[[:space:]](.+)[[:space:]]-\>[[:space:]](.+)$ ]]; then
    local indent="${BASH_REMATCH[1]}"
    local source="${BASH_REMATCH[2]}"
    local dest="${BASH_REMATCH[3]}"
    echo -e "${indent}Processing: ${DIM}${source}${NC} → ${CYAN}${dest}${NC}" >&2
  # Color values in "key: value" patterns
  elif [[ "$message" =~ ^([[:space:]]*)([^:]+):[[:space:]](.+)$ ]]; then
    local indent="${BASH_REMATCH[1]}"
    local key="${BASH_REMATCH[2]}"
    local value="${BASH_REMATCH[3]}"
    echo -e "${indent}${key}: ${CYAN}${value}${NC}" >&2
  else
    echo -e "$message" >&2
  fi
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

# Structured output helpers
log_section() {
  echo -e "\n${BOLD}=== $1 ===${NC}" >&2
}

log_service() {
  # Shows [1/3] service_name format
  echo -e "\n${CYAN}[$1/$2] $3${NC}" >&2
}

log_script() {
  # Shows >>> Running script.sh format
  echo -e "  ${PURPLE}>>>${NC} Running ${1}" >&2
}

log_env_source() {
  # Shows environment source file
  echo -e "    ${DIM}From $1:${NC}" >&2
}

# Display Docker port mappings in a clean format
log_ports() {
  local ports="$1"
  [ -z "$ports" ] && return
  
  echo -e "  ${GREEN}✓${NC} Ports:" >&2
  echo "$ports" | while IFS= read -r line; do
    # Parse Docker's port output: "80/tcp -> 0.0.0.0:32768"
    local parsed=$(echo "$line" | awk -F'[ :/]+' '/tcp.*->/ {print $1 " " $NF}')
    if [ -n "$parsed" ]; then
      local container_port=$(echo "$parsed" | cut -d' ' -f1)
      local host_port=$(echo "$parsed" | cut -d' ' -f2)
      echo -e "    ${container_port} → ${CYAN}localhost:${host_port}${NC}" >&2
    else
      # Fallback for non-standard format
      echo -e "    ${DIM}${line}${NC}" >&2
    fi
  done
}

# Generate /etc/hosts entries for deployed services
generate_hosts_entries() {
  local entries=""
  for service_info in "$@"; do
    # Format: "service:deployment-service.local"
    local hostname="${service_info#*:}"
    entries="${entries}${DIM}127.0.0.1${NC} ${CYAN}${hostname}${NC}\n"
  done
  
  [ -n "$entries" ] && echo -e "\n${DIM}To use Docker hostnames instead of localhost, add to /etc/hosts:${NC}\n${entries}"
}

# Load environment variables from a file
# Tracks source for each variable to show in deployment output
load_env_file() {
  local env_file="$1"
  [ ! -f "${env_file}" ] && return
  
  # Process each line
  while IFS='=' read -r key value; do
    # Skip comments and empty lines
    [[ "$key" =~ ^[[:space:]]*# ]] && continue
    [ -z "$key" ] && continue
    
    # Trim whitespace
    key="${key#"${key%%[![:space:]]*}"}"
    key="${key%"${key##*[![:space:]]}"}"
    
    # Only set if not already set (preserve CLI overrides)
    if [ -z "${!key}" ]; then
      export "$key=$value"
      # Track where this variable came from
      export "YAGET_SOURCE_${key}=${env_file}"
    fi
  done < "$env_file"
}

# Show environment variables grouped by their source file
show_env_by_source() {
  # Get all unique source files
  local source_files=$(env | grep '^YAGET_SOURCE_' | cut -d= -f2- | sort -u)
  
  for source_file in $source_files; do
    log_env_source "$source_file"
    
    # Find all variables from this source
    env | grep '^YAGET_SOURCE_' | while IFS='=' read -r key value; do
      local var_name="${key#YAGET_SOURCE_}"
      
      # Skip YAGET-managed variables (these are set by YAGET, not user)
      [[ "$var_name" =~ ^(HOSTNAME|CONTAINER_NAME|SERVICE_NAME|DEPLOYMENT_NAME|NETWORK_NAME|SERVICE_DIR|CONFIG_PATH|TEMPLATE_DIR)$ ]] && continue
      
      if [ "$value" = "$source_file" ]; then
        # Show the actual value of the variable with color
        echo -e "      ${var_name}=${CYAN}${!var_name}${NC}" >&2
      fi
    done
  done
}

# Utility functions
print_banner() {
  cat >&2 << 'EOF'
 __  __     ______     ______     ______     ______  
/\ \_\ \   /\  __ \   /\  ___\   /\  ___\   /\__  _\ 
\ \____ \  \ \  __ \  \ \ \__ \  \ \  __\   \/_/\ \/ 
 \/\_____\  \ \_\ \_\  \ \_____\  \ \_____\    \ \_\ 
  \/_____/   \/_/\/_/   \/_____/   \/_____/     \/_/ 
                                                     
  ¯\_(ツ)_/¯ <(Yet Another GitLab Environment Tool)

EOF
}

get_script_dir() {
  echo "${SCRIPT_DIR}"
}

get_artifacts_root() {
  echo "${YAGET_ARTIFACTS_ROOT:-${SCRIPT_DIR}/artifacts}"
}

# Exit with error message
die() {
  log_error "$1"
  exit 1
}
