# Using Templates

## Quick Setup

Templates are maintained in a separate repository for independent versioning:

```bash
# Symlink method (recommended)
git clone git@gitlab.com:gitlab-yaker/yaget-templates ../yaget-templates
ln -sf ../yaget-templates templates

# Or use custom location
git clone git@gitlab.com:gitlab-yaker/yaget-templates /shared/templates
export YAGET_TEMPLATES_DIR=/shared/templates
```

## Template Structure

```
templates/deployment-name/
├── .env                      # Deployment defaults (optional)
└── service-name/
    ├── .env                  # Service defaults (optional)
    ├── docker-compose.yml.tpl # Custom compose file (optional)
    ├── gitlab.rb.tpl         # Processed with envsubst
    ├── gitlab.rb             # Copied as-is
    ├── pre-deploy.sh         # Pre-start script (optional)
    └── post-deploy.sh        # Post-start script (optional)
```

## Available Variables

YAGET provides these variables to all `.tpl` files:

| Variable | Value | Example |
|----------|-------|---------|
| `$DEPLOYMENT_NAME` | Deployment name | `sso` |
| `$SERVICE_NAME` | Service name | `gitlab` |
| `$CONTAINER_NAME` | Full container name | `sso-gitlab` |
| `$HOSTNAME` | Docker hostname | `sso-gitlab.local` |
| `$NETWORK_NAME` | Docker network | `sso-network` |
| `$SERVICE_DIR` | Service artifacts path | `/path/to/artifacts/sso/gitlab` |
| `$CONFIG_PATH` | Same as SERVICE_DIR | `/path/to/artifacts/sso/gitlab` |
| `$TEMPLATE_DIR` | Template source path | `/path/to/templates/sso` |

## Environment Variables

Set template variables via:

1. **Root `.env` file** - Global defaults (lowest precedence)
2. **Deployment `.env` file** - All services within that deployment
3. **Service `.env` files** - Service-specific defaults  
4. **Command line** - Global, applies to all services (highest precedence)

```bash
# Examples
GITLAB_VERSION=16.0.0 ./deploy.sh basic
export EXTERNAL_URL=https://gitlab.test
```

The deployment output shows which variables came from which source.

## Template Processing

- Except for pre and post deploy scripts, files ending in `.tpl` are processed with `envsubst` (`.tpl` extension removed)
- All other files are copied as-is
- Scripts (`pre-deploy.sh`, `post-deploy.sh`) are NOT processed but have access to all [Available Variables](#available-variables)
- **Important**: `envsubst` only supports `$VAR` and `${VAR}` syntax

## Docker Requirements

Always use bind mounts to `$SERVICE_DIR/volumes/`:

```yaml
volumes:
  - "${SERVICE_DIR}/volumes/data:/var/opt/gitlab"
  - "${CONFIG_PATH}/gitlab.rb:/etc/gitlab/gitlab.rb"
```

Enable Docker hostnames with:
```yaml
hostname: "${HOSTNAME}"
```

## Troubleshooting

**Template not found**: Check `YAGET_TEMPLATES_DIR` points to correct location
**Variable not substituted**: Ensure `.tpl` extension and `${VAR}` syntax
**Permission denied**: Check script files are executable (`chmod +x`)

---

For comprehensive template authoring guide, see the [YAGET-Templates repository](https://gitlab.com/gitlab-yaker/yaget-templates).
