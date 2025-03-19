# Template Reference Guide

This document provides a reference for creating and customizing templates used in the GitLab test environment system.

## Base Docker Compose Template

The base `docker-compose.yml.template` file defines the standard configuration for a GitLab service.

### Available Variables

The following environment variables are available for substitution in templates:

| Variable | Description | Example Value |
|----------|-------------|--------------|
| `$SERVICE_NAME` | Name of the service derived from directory name | `gitlab` |
| `$CONTAINER_NAME` | Full container name | `deployment-name-gitlab` |
| `$DEPLOYMENT_NAME` | Name of the deployment | `deployment-name` |
| `$NETWORK_NAME` | Docker network name | `deployment-name-network` |
| `$CONFIG_PATH` | Path to configuration file | `/path/to/gitlab.rb` |
| `$GITLAB_VERSION` | GitLab version | `15.11.3-ee.0` |
| `$HTTP_PORT` | HTTP port (randomized) | `12345` |
| `$HTTPS_PORT` | HTTPS port (randomized) | `12445` |
| `$SSH_PORT` | SSH port (randomized) | `12545` |
| `$SERVICE_DIR` | Path to service directory | `/path/to/service-dir` |

### Template Syntax

Variables in templates use the `$VARIABLE` or `${VARIABLE}` syntax which is processed by `envsubst`.

Example variable usage:
```yaml
services:
  $SERVICE_NAME:
    image: "gitlab/gitlab-ee:${GITLAB_VERSION:-latest}"
```

Default values can be specified with `${VARIABLE:-default}` syntax:
```yaml
ports:
  - "${HTTP_PORT:-80}:80"
```

## Custom Docker Compose Templates

You can create custom templates for specific services by adding a file named `docker-compose.service-name.yml.template` in the service directory.

### Example: Custom Template for LDAP

```yaml
version: '3.8'

services:
  $SERVICE_NAME:
    image: "osixia/openldap:1.5.0"
    environment:
      - LDAP_DOMAIN=example.org
      - LDAP_ADMIN_PASSWORD=admin
    volumes:
      - "./ldif:/container/service/slapd/assets/config/bootstrap/ldif/custom"
    ports:
      - "${LDAP_PORT:-$((10000 + RANDOM % 1000))}:389"
      - "${LDAPS_PORT:-$((10000 + RANDOM % 1000))}:636"
```

### Example: Custom Template with Service Dependencies

```yaml
version: '3.8'

services:
  $SERVICE_NAME:
    image: "gitlab/gitlab-ee:${GITLAB_VERSION:-latest}"
    depends_on:
      - anotherservice
```

## Post-Deployment Scripts

You can add post-deployment automation by creating an executable `post-deploy.sh` script in a service directory. This script will run automatically after all services are deployed.

### Variables Available to Post-Deployment Scripts

Post-deployment scripts have access to the following environment variables:

- `DEPLOYMENT_NAME`: The name of the deployment
- `NETWORK_NAME`: The Docker network name
- Container names follow the pattern `${DEPLOYMENT_NAME}-${SERVICE_NAME}`

### Example: LDAP Post-Deployment Script

```bash
#!/bin/bash
# Wait for LDAP to be ready
sleep 5

# Add LDIF entries to LDAP
docker exec sso-ldap ldapadd -c -x -H ldap://localhost:389 \
  -D "cn=admin,dc=example,dc=org" -w admin \
  -f /container/service/slapd/assets/config/bootstrap/ldif/custom/users.ldif
```

## Working with Paths in Templates

When using relative paths in templates, be aware that Docker Compose resolves them relative to the location of the compose file, not the template. 

To ensure correct path resolution:

1. **Use absolute paths** when possible
2. **Use environment variables** like `$SERVICE_DIR` for paths
3. **Use the current directory** (`./`) for files that are in the service directory
4. **Verify paths** in the generated compose file if you encounter issues

### Example: Correct Path Usage

```yaml
volumes:
  - "${SERVICE_DIR}/ldif:/container/service/slapd/assets/config/bootstrap/ldif/custom"
```

## Template Processing

Templates are processed in this order:

1. Template file is selected (custom or base)
2. Environment variables are exported
3. Template is processed with `envsubst`
4. Processed file is used by Docker Compose
5. Temporary file is deleted after deployment

The final processed file exists only temporarily during deployment.