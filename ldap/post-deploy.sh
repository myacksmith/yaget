#!/bin/bash

# Color codes for output formatting
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Running post-deployment steps for LDAP environment...${NC}"

# Wait for GitLab to fully initialize
GITLAB_CONTAINER="${DEPLOYMENT_NAME:-gitlab-ldap}-gitlab"
echo -e "${YELLOW}Waiting for GitLab to be ready...${NC}"
timeout 300 bash -c "until docker exec $GITLAB_CONTAINER gitlab-ctl status > /dev/null 2>&1; do sleep 5; done"

if [ $? -ne 0 ]; then
    echo -e "${RED}Timeout waiting for GitLab to start${NC}"
    exit 1
fi

echo -e "${GREEN}LDAP environment is ready!${NC}"
echo -e "\n${YELLOW}LDAP User Credentials:${NC}"
echo -e "Username: ${GREEN}john${NC}"
echo -e "Password: ${GREEN}password${NC}"
echo -e "Email: ${GREEN}john.doe@example.org${NC}"
echo -e "\nUsername: ${GREEN}jane${NC}"
echo -e "Password: ${GREEN}password${NC}"
echo -e "Email: ${GREEN}jane.smith@example.org${NC}"
echo -e "\nUsername: ${GREEN}admin${NC} (LDAP admin user)"
echo -e "Password: ${GREEN}password${NC}"
echo -e "Email: ${GREEN}admin@example.org${NC}"

echo -e "\n${YELLOW}LDAP Admin Interface:${NC}"
echo -e "URL: ${GREEN}http://gitlab.local:${LDAPADMIN_PORT:-8081}${NC}"
echo -e "Login DN: ${GREEN}cn=admin,dc=example,dc=org${NC}"
echo -e "Password: ${GREEN}${LDAP_ADMIN_PASSWORD:-admin}${NC}"

echo -e "\n${BLUE}Testing LDAP connection from GitLab...${NC}"
docker exec $GITLAB_CONTAINER gitlab-rake gitlab:ldap:check

echo -e "\n${GREEN}Post-deployment steps completed${NC}"
