#!/bin/bash
set -eo pipefail

# install_dependencies.sh
# Purpose: Install or verify dependencies for GitLab test environment
# Usage: ./install_dependencies.sh

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log with timestamp and color
log() {
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo -e "${BLUE}[${timestamp}] INFO: $1${NC}"
}

log_success() {
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo -e "${GREEN}[${timestamp}] SUCCESS: $1${NC}"
}

log_warn() {
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo -e "${YELLOW}[${timestamp}] WARN: $1${NC}"
}

log_error() {
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo -e "${RED}[${timestamp}] ERROR: $1${NC}"
}

# Check for docker
if ! command -v docker &> /dev/null; then
  log_error "Docker is not installed."
  echo "Please install Docker first, then run this script again."
  echo "Visit https://docs.docker.com/get-docker/ for installation instructions."
  exit 1
fi

# Check for docker compose
if ! docker compose version &> /dev/null; then
  log_warn "Docker Compose V2 plugin not detected."
  echo "Please ensure Docker Compose V2 is installed."
  echo "Visit https://docs.docker.com/compose/install/ for installation instructions."
  exit 1
fi

# Check for envsubst (part of gettext)
if ! command -v envsubst &> /dev/null; then
  log_error "envsubst is not installed (part of gettext package)."
  
  # Provide installation instructions based on OS
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "For Debian/Ubuntu: sudo apt-get install gettext"
    echo "For RedHat/CentOS: sudo yum install gettext"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "For MacOS: brew install gettext && brew link --force gettext"
  else
    echo "Please install the gettext package for your operating system."
  fi
  
  exit 1
fi

# Make scripts executable
chmod +x deploy.sh destroy.sh

log_success "All dependencies are installed!"
echo ""
echo "You can now use the GitLab test environment deployment system."
echo "Run './deploy.sh --help' for usage instructions."