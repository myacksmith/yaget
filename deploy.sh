#!/bin/bash

# Color codes for output formatting
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Display script banner
echo -e "${BLUE}"
echo "  _____ _ _   _           _        _____                                      "
echo " / ____(_) | | |         | |      / ____|                                     "
echo "| |  __ _| |_| |     __ _| |__   | |     ___  _ __ ___  _ __   ___  ___  ___ "
echo "| | |_ | | __| |    / _\` | '_ \  | |    / _ \| '_ \` _ \| '_ \ / _ \/ __|/ _ \\"
echo "| |__| | | |_| |___| (_| | |_) | | |___| (_) | | | | | | |_) | (_) \__ \  __/"
echo " \_____|_|\__|______\__,_|_.__/   \_____\___/|_| |_| |_| .__/ \___/|___/\___|"
echo "                                                        | |                   "
echo "                                                        |_|                   "
echo -e "${NC}"
echo -e "${GREEN}GitLab Test Environment Deployer${NC}"
echo ""

# Set script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Available environments
ENVIRONMENTS=(base ldap gitaly-cluster geo runners external-db custom)

# Function to show usage information
show_usage() {
    echo -e "${YELLOW}Usage:${NC}"
    echo -e "  ./deploy.sh <environment> [options]"
    echo ""
    echo -e "${YELLOW}Available environments:${NC}"
    echo "  base          - Standard GitLab EE instance"
    echo "  ldap          - GitLab with LDAP authentication"
    echo "  gitaly-cluster - GitLab with Gitaly cluster"
    echo "  geo           - GitLab with Geo replication"
    echo "  runners       - GitLab with CI runners"
    echo "  external-db   - GitLab with external PostgreSQL"
    echo "  custom        - Custom configuration"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo "  -v, --version VERSION  - Specify GitLab version (default: latest)"
    echo "  -n, --name NAME        - Custom deployment name (default: environment name)"
    echo "  -c, --config FILE      - Custom gitlab.rb file path"
    echo "  -h, --help             - Show this help message"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  ./deploy.sh base"
    echo "  ./deploy.sh ldap -v 15.11.3-ee.0"
    echo "  ./deploy.sh geo --name geo-test"
    echo "  ./deploy.sh base --config /path/to/custom/gitlab.rb"
    echo ""
}

# Function to validate environment
validate_environment() {
    local env=$1
    for valid_env in "${ENVIRONMENTS[@]}"; do
        if [[ "$env" == "$valid_env" ]]; then
            return 0
        fi
    done
    return 1
}

# Function to deploy the environment
deploy_environment() {
    local env=$1
    local version=$2
    local name=$3
    local custom_config=$4
    
    # Default to environment name if no custom name provided
    if [[ -z "$name" ]]; then
        name=$env
    fi
    
    echo -e "${GREEN}Deploying GitLab $env environment as '$name'${NC}"
    
    if [[ ! -d "$env" ]]; then
        echo -e "${RED}Error: Environment directory '$env' not found${NC}"
        exit 1
    fi
    
    # Create deployment directory
    DEPLOY_DIR="deployments/$name"
    mkdir -p "$DEPLOY_DIR"
    
    # Copy environment files to deployment directory
    cp -r "$env"/* "$DEPLOY_DIR/"
    
    # Ensure config directory exists
    mkdir -p "$DEPLOY_DIR/config"
    
    # Handle gitlab.rb configuration
    if [[ -n "$custom_config" ]]; then
        if [[ ! -f "$custom_config" ]]; then
            echo -e "${RED}Error: Custom config file '$custom_config' not found${NC}"
            exit 1
        fi
        
        echo -e "${BLUE}Using custom gitlab.rb configuration${NC}"
        cp "$custom_config" "$DEPLOY_DIR/config/gitlab.rb"
    elif [[ ! -f "$DEPLOY_DIR/config/gitlab.rb" && ! -f "$env/config/gitlab.rb" ]]; then
        echo -e "${RED}Error: No gitlab.rb configuration found for this environment${NC}"
        echo -e "Please provide a configuration file with --config or create one at $env/config/gitlab.rb"
        rm -rf "$DEPLOY_DIR"
        exit 1
    fi
    
    # Create .env file if it doesn't exist
    if [[ ! -f "$DEPLOY_DIR/.env" ]]; then
        touch "$DEPLOY_DIR/.env"
    fi
    
    # Set GitLab version if specified
    if [[ -n "$version" ]]; then
        echo -e "${BLUE}Setting GitLab version to $version${NC}"
        if grep -q "GITLAB_VERSION=" "$DEPLOY_DIR/.env"; then
            sed -i "s/GITLAB_VERSION=.*/GITLAB_VERSION=$version/" "$DEPLOY_DIR/.env"
        else
            echo "GITLAB_VERSION=$version" >> "$DEPLOY_DIR/.env"
        fi
    fi
    
    # Add deployment name to .env
    if grep -q "DEPLOYMENT_NAME=" "$DEPLOY_DIR/.env"; then
        sed -i.bak "s/DEPLOYMENT_NAME=.*/DEPLOYMENT_NAME=$name/" "$DEPLOY_DIR/.env"
        rm -f "$DEPLOY_DIR/.env.bak"
    else
        echo "DEPLOYMENT_NAME=$name" >> "$DEPLOY_DIR/.env"
    fi
    
    # Run pre-deploy script if exists
    if [[ -f "$DEPLOY_DIR/pre-deploy.sh" ]]; then
        echo -e "${BLUE}Running pre-deployment script...${NC}"
        chmod +x "$DEPLOY_DIR/pre-deploy.sh"
        (cd "$DEPLOY_DIR" && ./pre-deploy.sh)
    fi
    
    # Deploy using docker compose
    echo -e "${BLUE}Starting containers...${NC}"
    (cd "$DEPLOY_DIR" && docker compose up -d)
    
    # Check if deployment was successful
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Deployment successful!${NC}"
        echo -e "${BLUE}Deployment directory:${NC} $DEPLOY_DIR"
        
        # Display URLs and access information
        echo -e "\n${YELLOW}Access Information:${NC}"
        
        # Find GitLab container
        GITLAB_CONTAINER=$(cd "$DEPLOY_DIR" && docker compose ps -q gitlab)
        if [[ -n "$GITLAB_CONTAINER" ]]; then
            # Get port mappings
            HTTP_PORT=$(docker port "$GITLAB_CONTAINER" 80 | cut -d ":" -f 2)
            HTTPS_PORT=$(docker port "$GITLAB_CONTAINER" 443 | cut -d ":" -f 2 2>/dev/null)
            SSH_PORT=$(docker port "$GITLAB_CONTAINER" 22 | cut -d ":" -f 2 2>/dev/null)
            
            if [[ -n "$HTTP_PORT" ]]; then
                echo -e "GitLab Web UI: ${GREEN}http://gitlab.local:$HTTP_PORT${NC}"
            fi
            if [[ -n "$HTTPS_PORT" ]]; then
                echo -e "GitLab HTTPS: ${GREEN}https://gitlab.local:$HTTPS_PORT${NC}"
            fi
            if [[ -n "$SSH_PORT" ]]; then
                echo -e "GitLab SSH: ${GREEN}ssh://gitlab.local:$SSH_PORT${NC}"
            fi
            
            echo -e "\nDefault login: ${GREEN}root${NC}"
            echo -e "Default password: ${GREEN}Check the logs for initial root password${NC}"
            echo -e "Run: ${BLUE}docker exec -it $GITLAB_CONTAINER grep 'Password:' /etc/gitlab/initial_root_password${NC}"
        fi
        
        # Run post-deploy script if exists
        if [[ -f "$DEPLOY_DIR/post-deploy.sh" ]]; then
            echo -e "\n${BLUE}Running post-deployment script...${NC}"
            chmod +x "$DEPLOY_DIR/post-deploy.sh"
            (cd "$DEPLOY_DIR" && ./post-deploy.sh)
        fi
        
        echo -e "\n${YELLOW}Configuration:${NC}"
        echo -e "GitLab configuration file: ${BLUE}$DEPLOY_DIR/config/gitlab.rb${NC}"
        echo -e "To modify configuration:"
        echo -e "1. Edit the gitlab.rb file"
        echo -e "2. Restart GitLab: ${BLUE}cd $DEPLOY_DIR && docker compose restart gitlab${NC}"
        
        echo -e "\n${YELLOW}To stop and remove this deployment:${NC}"
        echo -e "  ./destroy.sh $name"
    else
        echo -e "${RED}Deployment failed!${NC}"
        echo -e "Check logs for more information:"
        echo -e "  cd $DEPLOY_DIR && docker compose logs"
    fi
}

# Parse command line arguments
if [[ $# -eq 0 ]]; then
    show_usage
    exit 0
fi

ENV=""
VERSION=""
NAME=""
CONFIG=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -n|--name)
            NAME="$2"
            shift 2
            ;;
        -c|--config)
            CONFIG="$2"
            shift 2
            ;;
        *)
            if [[ -z "$ENV" ]]; then
                ENV="$1"
                shift
            else
                echo -e "${RED}Error: Unexpected argument '$1'${NC}"
                show_usage
                exit 1
            fi
            ;;
    esac
done

# Validate environment
if ! validate_environment "$ENV"; then
    echo -e "${RED}Error: Invalid environment '$ENV'${NC}"
    show_usage
    exit 1
fi

# Deploy the environment
deploy_environment "$ENV" "$VERSION" "$NAME" "$CONFIG"
