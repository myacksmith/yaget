#!/bin/bash
# Load initial LDAP data after container starts

echo "Waiting for LDAP to be ready..."
sleep 10

# Add users from LDIF file
docker exec -i ${CONTAINER_NAME} ldapadd \
  -x -D "cn=admin,${LDAP_BASE}" -w "${LDAP_ADMIN_PASSWORD}" \
  < ldif/users.ldif || echo "Users may already exist"

echo "LDAP users loaded"