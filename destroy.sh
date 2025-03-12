#!/bin/bash

# Color codes for output formatting
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Set script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Function to show usage information
show_usage() {
    echo -e "${YELLOW}Usage:${NC}"
    echo -e "  ./destroy.sh <deployment-name> [options]"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo "  -f, --force       - Force removal without confirmation"
    echo "  -k, --keep-data   - Keep volumes and data (default: remove everything)"
    echo "  -h, --help        - Show this help message"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  ./destroy.sh base"
    echo "  ./destroy.sh ldap-test --force"
    echo "  ./destroy.sh geo-primary --keep-data"
    echo ""
}

# Function to destroy the environment
destroy_environment() {
    local name=$1
    local force=$2
    local keep_data=$3

    DEPLOY_DIR="deployments/$name"

    if [[ ! -d "$DEPLOY_DIR" ]]; then
        echo -e "${RED}Error: Deployment '$name' not found in 'deployments/' directory${NC}"
        exit 1
    fi
    
    # Confirm destruction unless force flag is set
    if [[ "$force" != "true" ]]; then
        echo -e "${YELLOW}WARNING: This will stop and remove the '$name' deployment.${NC}"
        if [[ "$keep_data" != "true" ]]; then
            echo -e "${RED}All data will be lost!${NC}"
        fi
        read -p "Are you sure you want to continue [y/N] " -n 1 -read
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Operation cancelled.${NC}"
            exit 0
        fi
    fi

    echo -e "${YELLOW}Stopping containers..."

