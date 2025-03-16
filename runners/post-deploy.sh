#!/bin/bash

# Color codes for output formatting
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Running post-deployment steps for CI/CD Runners environment...${NC}"

# Wait for GitLab to fully initialize
GITLAB_CONTAINER="${DEPLOYMENT_NAME:-gitlab-runners}"
RUNNER_SHELL_CONTAINER="${DEPLOYMENT_NAME:-gitlab-runners}-shell"
RUNNER_DOCKER_CONTAINER="${DEPLOYMENT_NAME:-gitlab-runners}-docker"

echo -e "${YELLOW}Waiting for GitLab to be ready...${NC}"
timeout 300 bash -c "until docker exec $GITLAB_CONTAINER gitlab-ctl status > /dev/null 2>&1; do sleep 5; done"

if [ $? -ne 0 ]; then
    echo -e "${RED}Timeout waiting for GitLab to start${NC}"
    exit 1
fi

# Get root password
echo -e "${YELLOW}Getting root password...${NC}"
ROOT_PASSWORD=$(docker exec $GITLAB_CONTAINER grep 'Password:' /etc/gitlab/initial_root_password | awk '{print $2}')

if [ -z "$ROOT_PASSWORD" ]; then
    echo -e "${RED}Could not retrieve root password${NC}"
    exit 1
fi

# Get registration token
echo -e "${YELLOW}Getting runner registration token...${NC}"
# Wait a bit more for Rails to be fully loaded
sleep 10
REGISTRATION_TOKEN=$(docker exec $GITLAB_CONTAINER gitlab-rails runner "puts Gitlab::CurrentSettings.current_application_settings.runners_registration_token")

if [ -z "$REGISTRATION_TOKEN" ]; then
    echo -e "${RED}Could not retrieve runner registration token${NC}"
    echo -e "${YELLOW}You may need to manually register runners after GitLab fully starts${NC}"
    exit 1
fi

# Register shell runner
echo -e "${YELLOW}Registering shell runner...${NC}"
docker exec $RUNNER_SHELL_CONTAINER sed -i "s/REGISTRATION_TOKEN_PLACEHOLDER/$REGISTRATION_TOKEN/" /etc/gitlab-runner/config.toml
docker exec $RUNNER_SHELL_CONTAINER gitlab-runner restart

# Register docker runner
echo -e "${YELLOW}Registering docker runner...${NC}"
docker exec $RUNNER_DOCKER_CONTAINER sed -i "s/REGISTRATION_TOKEN_PLACEHOLDER/$REGISTRATION_TOKEN/" /etc/gitlab-runner/config.toml
docker exec $RUNNER_DOCKER_CONTAINER gitlab-runner restart

echo -e "${GREEN}CI/CD Runners environment is ready!${NC}"
echo -e "\n${YELLOW}Available runners:${NC}"
echo -e "- Shell runner (for simple commands)"
echo -e "- Docker runner (for containerized builds)"

echo -e "\n${YELLOW}To check runner status:${NC}"
echo -e "Shell runner: ${BLUE}docker exec $RUNNER_SHELL_CONTAINER gitlab-runner list${NC}"
echo -e "Docker runner: ${BLUE}docker exec $RUNNER_DOCKER_CONTAINER gitlab-runner list${NC}"

echo -e "\n${YELLOW}To use these runners:${NC}"
echo -e "1. Create a project in GitLab"
echo -e "2. Add a .gitlab-ci.yml file to your project"
echo -e "3. Runners will automatically pick up and run the jobs"

echo -e "\n${GREEN}Post-deployment steps completed${NC}"
