# Template Reference Guide

This document provides a reference for creating and customizing templates in the GitLab test environment system.

## Available Variables

The following environment variables are available in templates:

| Variable | Description | Example Value |
|----------|-------------|--------------|
| `$SERVICE_NAME` | Name of the service derived from directory name | `gitlab` |
| `$CONTAINER_NAME` | Full container name | `deployment-name-gitlab` |
| `$DEPLOYMENT_NAME` | Name of the deployment | `deployment-name` |
| `$NETWORK_NAME` | Docker network name | `deployment-name-network` |
| `$CONFIG_PATH` | Path to service directory | `/path/to/service-dir` |
| `$GITLAB_VERSION` | GitLab version specified at deploy time | `15.11.3-ee.0` |
| `$HTTP_PORT` | HTTP port (randomized + service index) | `12345` |
| `$HTTPS_PORT` | HTTPS port (randomized + service index) | `12445` |
| `$SSH_PORT` | SSH port (randomized + service index) | `12545` |
| `$SERVICE_DIR` | Path to service directory | `/path/to/service-dir` |
| `$SERVICE_INDEX` | Index of service in deployment (for port offsets) | `0`, `1`, etc. |

## Custom Templates

You can create custom templates in two ways:
1. `docker-compose.service-name.template` - Template file processed by envsubst
2. `docker-compose.service-name.yml` - Direct Docker Compose file

## Environment Variable Priority

Variables are processed in this order (higher overrides lower):
1. Service-specific script variables (SERVICE_NAME, ports, etc.)
2. Project-level `.env` file at root
3. Service-specific `.env` file in service directory

## Template Example

```yaml
services:
  $SERVICE_NAME:
    image: "osixia/openldap:1.5.0"
    environment:
      - LDAP_DOMAIN=${LDAP_DOMAIN:-example.org}
    volumes:
      - "${SERVICE_DIR}/ldif:/custom/ldif"
    ports:
      - "${LDAP_PORT:-389}:389"
```

## Post-Deployment Scripts

Create an executable `post-deploy.sh` script in a service directory to run custom commands after deployment.

```bash
#!/bin/bash
# Simple post-deployment script
docker exec ${DEPLOYMENT_NAME}-${SERVICE_NAME} some-command
```