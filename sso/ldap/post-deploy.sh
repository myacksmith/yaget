#!/bin/bash
# post-deploy.sh for LDAP service
# This script adds LDIF entries to the LDAP directory after container startup

# Color definitions for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Set variables
CONTAINER_NAME="sso-ldap"
ADMIN_DN="cn=admin,dc=example,dc=org"
ADMIN_PASSWORD="admin"
BASE_DN="dc=example,dc=org"
LDIF_PATH="/container/service/slapd/assets/config/bootstrap/ldif/custom/users.ldif"
MAX_RETRIES=10
SLEEP_INTERVAL=5

log() {
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo -e "${BLUE}[${timestamp}] LDAP POST-DEPLOY: $1${NC}"
}

log_success() {
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo -e "${GREEN}[${timestamp}] LDAP POST-DEPLOY: $1${NC}"
}

log_warn() {
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo -e "${YELLOW}[${timestamp}] LDAP POST-DEPLOY: $1${NC}"
}

log_error() {
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo -e "${RED}[${timestamp}] LDAP POST-DEPLOY: $1${NC}"
}

# Wait for the LDAP container to be ready
log "Waiting for LDAP service to become ready..."
for i in $(seq 1 $MAX_RETRIES); do
  if docker exec $CONTAINER_NAME ldapsearch -x -H ldap://localhost:389 -b "" -s base &>/dev/null; then
    log "LDAP service is up and running"
    break
  fi
  
  if [ $i -eq $MAX_RETRIES ]; then
    log_error "LDAP service did not become ready in time. Aborting."
    exit 1
  fi
  
  log "Attempt $i/$MAX_RETRIES: LDAP service not ready yet. Waiting $SLEEP_INTERVAL seconds..."
  sleep $SLEEP_INTERVAL
done

# Check if base DN exists
log "Checking if base DN exists..."
if docker exec $CONTAINER_NAME ldapsearch -x -H ldap://localhost:389 -D "$ADMIN_DN" -w "$ADMIN_PASSWORD" -b "$BASE_DN" -s base &>/dev/null; then
  log "Base DN exists. Proceeding with user import."
else
  log_warn "Base DN does not exist. This is unusual and may indicate a configuration issue."
  log "Attempting to create base DN..."
  
  # Create a temporary LDIF file for the base entry
  BASE_LDIF=$(mktemp)
  cat > $BASE_LDIF << EOF
dn: dc=example,dc=org
objectClass: dcObject
objectClass: organization
o: Example Organization
dc: example
EOF

  # Add base DN to LDAP
  docker cp $BASE_LDIF $CONTAINER_NAME:/tmp/base.ldif
  docker exec $CONTAINER_NAME ldapadd -x -H ldap://localhost:389 -D "$ADMIN_DN" -w "$ADMIN_PASSWORD" -f /tmp/base.ldif || {
    log_error "Failed to add base DN. Check LDAP configuration."
    rm $BASE_LDIF
    exit 1
  }
  
  rm $BASE_LDIF
  log_success "Base DN created successfully."
fi

# Add LDIF entries to LDAP
log "Adding LDIF entries to LDAP directory..."
docker exec $CONTAINER_NAME ldapadd -c -x -H ldap://localhost:389 -D "$ADMIN_DN" -w "$ADMIN_PASSWORD" -f "$LDIF_PATH" || {
  log_warn "Some entries may already exist. This is normal for redeployments."
}

# Verify users were added
log "Verifying users were added..."
USER_COUNT=$(docker exec $CONTAINER_NAME ldapsearch -x -H ldap://localhost:389 -D "$ADMIN_DN" -w "$ADMIN_PASSWORD" -b "$BASE_DN" "(objectClass=inetOrgPerson)" | grep -c "^dn:")

if [ $USER_COUNT -gt 0 ]; then
  log_success "Successfully added $USER_COUNT users to LDAP directory"
else
  log_error "No users found in LDAP directory after import. Check configuration and LDIF file."
  exit 1
fi

log_success "LDAP post-deployment completed successfully!"
