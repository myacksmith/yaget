# Template Reference

## Structure

```
templates/
└── deployment-name/
    ├── .env                      # Deployment defaults (optional)
    └── service-name/
        ├── .env                  # Service defaults (optional)
        ├── docker-compose.yml.tpl # Custom compose file (optional)
        ├── *.tpl                 # Any .tpl file gets processed
        ├── pre-deploy.sh         # Pre-start script (optional)
        └── post-deploy.sh        # Post-start script (optional)
```

## Template Processing

- Files ending in `.tpl` are processed with `envsubst`
- The `.tpl` extension is removed
- All other files are copied as-is

**Important**: `envsubst` only supports `$VAR` and `${VAR}`. No bash expansions like `${VAR:-default}`.

## Variables

YAGET provides these variables to all templates:

| Variable | Value | Example |
|----------|-------|---------|
| `$DEPLOYMENT_NAME` | Deployment name | `sso` |
| `$SERVICE_NAME` | Service name | `gitlab` |
| `$CONTAINER_NAME` | Full container name | `sso-gitlab` |
| `$HOSTNAME` | Docker hostname | `sso-gitlab.local` |
| `$NETWORK_NAME` | Docker network | `sso-network` |
| `$SERVICE_DIR` | Service path in artifacts | `/path/to/artifacts/sso/gitlab` |
| `$CONFIG_PATH` | Same as SERVICE_DIR | `/path/to/artifacts/sso/gitlab` |
| `$TEMPLATE_DIR` | Template path | `/path/to/templates/sso` |

## Docker Hostnames

YAGET provides a `HOSTNAME` variable for each service. To enable the /etc/hosts feature shown at deployment end:

```yaml
services:
  ${SERVICE_NAME}:
    hostname: "${HOSTNAME}"
```

Without this, the container won't respond to the suggested hostname.

## Volume Requirements

Always use bind mounts to `$SERVICE_DIR/volumes/`:

```yaml
volumes:
  - "${SERVICE_DIR}/volumes/config:/etc/gitlab"
  - "${SERVICE_DIR}/volumes/logs:/var/log/gitlab"
  - "${SERVICE_DIR}/volumes/data:/var/opt/gitlab"
```

Never use Docker named volumes - they won't be cleaned up.

## Configuration Files

For GitLab, mount configs two ways:

```yaml
volumes:
  # Your config file
  - "${CONFIG_PATH}/gitlab.rb:/etc/gitlab/gitlab.rb"
  
  # Config directory (for GitLab-generated files)
  - "${SERVICE_DIR}/volumes/config:/etc/gitlab"
```

## Environment Variables

Set template variables via:

1. `.env` files in template directories
2. Command line: `VAR=value ./deploy.sh deployment`
3. Exported shell variables

Loading order (later overrides earlier):
1. Root `.env` file
2. Service `.env` files  
3. Command line/shell variables

The deployment output shows which variables came from which source.

## Custom Docker Compose

If no `docker-compose.yml.tpl` exists in the service directory, YAGET uses the default template.

To customize, create your own:
```
templates/mydeployment/gitlab/docker-compose.yml.tpl
```

## External Templates

```bash
# Use different template directory
YAGET_TEMPLATES_DIR=/shared/templates ./deploy.sh custom
```
