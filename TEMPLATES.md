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

| Variable | Value |
|----------|-------|
| `$DEPLOYMENT_NAME` | Deployment name (e.g., `basic`) |
| `$SERVICE_NAME` | Service name (e.g., `gitlab`) |
| `$CONTAINER_NAME` | Full name (e.g., `basic-gitlab`) |
| `$NETWORK_NAME` | Docker network (e.g., `basic-network`) |
| `$SERVICE_DIR` | Service path in artifacts |
| `$CONFIG_PATH` | Same as SERVICE_DIR |

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

For GitLab, we mount configs two ways:

```yaml
volumes:
  # Your config file (overrides anything in config dir)
  - "${CONFIG_PATH}/gitlab.rb:/etc/gitlab/gitlab.rb"
  
  # Config directory (for GitLab-generated files)
  - "${SERVICE_DIR}/volumes/config:/etc/gitlab"
```

This lets you provide custom configs while GitLab can still write its own files.

## Environment Variables

Templates use variables that must be set via:

1. `.env` files in template directories
2. Command line: `VAR=value ./deploy.sh deployment`
3. Exported shell variables

Loading order (later overrides earlier):
1. Root `.env` file
2. Service `.env` files  
3. Command line/shell variables

Example:
```bash
# templates/basic/gitlab/.env
GITLAB_VERSION=latest
EXTERNAL_URL=http://gitlab.local

# Override any variable
GITLAB_VERSION=16.0.0 ./deploy.sh basic
```

## Custom Docker Compose

If no `docker-compose.yml.tpl` exists in the service directory, YAGET uses the default template.

To customize, create your own:
```
templates/mydeployment/gitlab/docker-compose.yml.tpl
```

## External Templates

```bash
# Use different template directory
export YAGET_TEMPLATES_DIR=/shared/templates
./deploy.sh custom

# Or per-command
YAGET_TEMPLATES_DIR=~/my-templates ./deploy.sh test
```