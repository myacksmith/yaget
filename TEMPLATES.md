# Template Reference Guide

## Available Variables

The following environment variables are available in templates:

| Variable | Description | Example Value |
|----------|-------------|--------------|
| `$SERVICE_NAME` | Name of the service derived from directory name | `gitlab` |
| `$CONTAINER_NAME` | Full container name | `deployment-name-gitlab` |
| `$DEPLOYMENT_NAME` | Name of the deployment | `deployment-name` |
| `$NETWORK_NAME` | Docker network name | `deployment-name-network` |
| `$CONFIG_PATH` | Path to service directory. Used for `gitlab.rb` or other conf files (such as licenses) | `/path/to/service-dir` |
| `$GITLAB_VERSION` | GitLab version specified at deploy time | `15.11.3-ee.0` |
| `$HTTP_PORT` | HTTP port (randomized + service index) | `12345` |
| `$HTTPS_PORT` | HTTPS port (randomized + service index) | `12445` |
| `$SSH_PORT` | SSH port (randomized + service index) | `12545` |
| `$SERVICE_DIR` | Path to service directory | `/path/to/service-dir` |
| `$SERVICE_INDEX` | Index of service in deployment (for port offsets) | `0`, `1`, etc. |

Override their values by defining them in a `.env` file inside the Service, Deployment, or top-level directories.
Service takes precedence over Deployment, and Deployment takes precedence over the top-level directory.

Any variable defined in a `.env` file will be used to substitute its equivalent in template file. 

## Custom Templates

You can create custom templates in two ways:
1. `docker-compose.service-name.template` - Template file processed by envsubst
2. `docker-compose.service-name.yml` - Direct Docker Compose file. Doesn't use variable subsitution. 

## Template Example

```yaml
services:
  $SERVICE_NAME:
    image: "osixia/openldap:1.5.0"
    environment:
      - LDAP_DOMAIN=${LDAP_DOMAIN}
    volumes:
      - "${SERVICE_DIR}/ldif:/custom/ldif"
    ports:
      - "${LDAP_PORT}:389"
```

## Post-Deployment Scripts

Create an executable `post-deploy.sh` script in a service directory to run custom commands after deployment.

```bash
#!/bin/bash
# Simple post-deployment script
docker exec ${DEPLOYMENT_NAME}-${SERVICE_NAME} some-command
```

## Known Issues

1. `envsubst` only works with `$VAR` and `${VAR}`, so syntax such as `${VAR:-default_value}` won't work. 
