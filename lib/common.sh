#!/bin/bash
# common.sh - Shared functions for YAGET
# Provides logging and utility functions

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo -e "${BLUE}[${timestamp}] INFO: $1${NC}" >&2
}

log_success() {
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo -e "${GREEN}[${timestamp}] SUCCESS: $1${NC}" >&2
}

log_warn() {
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo -e "${YELLOW}[${timestamp}] WARN: $1${NC}" >&2
}

log_error() {
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo -e "${RED}[${timestamp}] ERROR: $1${NC}" >&2
}

# Utility functions
print_banner() {
  echo " __  __     ______     ______     ______     ______  "
  echo "/\ \_\ \   /\  __ \   /\  ___\   /\  ___\   /\__  _\ "
  echo "\ \____ \  \ \  __ \  \ \ \__ \  \ \  __\   \/_/\ \/ "
  echo " \/\_____\  \ \_\ \_\  \ \_____\  \ \_____\    \ \_\ "
  echo "  \/_____/   \/_/\/_/   \/_____/   \/_____/     \/_/ "
  echo "                                                     "
  echo "    (Yet Another GitLab Environment Tool)"
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
      fi
    done < "$env_file"
    
    log "Loaded environment from ${env_file}"
  fi
}

# Error handling
die() {
  log_error "$1"
  exit 1
}