# Template Reference Guide

## Template System

YAGET uses `envsubst` for template processing. Any file ending in `.tpl` will be processed:

- `config.toml.tpl` → `config.toml`
- `docker-compose.yml.tpl` → `docker-compose.yml`
- `gitlab.rb.tpl` → `gitlab.rb`
- `subdir/nginx.conf.tpl` → `subdir/nginx.conf`

**Important**: `envsubst` only supports `$VAR` and `${VAR}` syntax. Complex bash expansions like `${VAR:-default}` will NOT work.

## Available Variables

The following environment variables are available in all templates:

| Variable | Description | Example Value |
|----------|-------------|--------------|
| `$DEPLOYMENT_NAME` | Name of the deployment | `basic` |
| `$SERVICE_NAME` | Name of the service | `gitlab` |
| `$CONTAINER_NAME` | Full container name | `basic-gitlab` |
| `$HOSTNAME` | Container hostname | `basic-gitlab.local` |
| `$NETWORK_NAME` | Docker network name | `basic-network` |
| `$SERVICE_DIR` | Path to service in artifacts | `/path/to/artifacts/basic/gitlab` |
| `$CONFIG_PATH` | Alias for SERVICE_DIR | `/path/to/artifacts/basic/gitlab` |
| `$TEMPLATE_DIR` | Path to source templates | `/path/to/yaget/basic` |

Additional variables can be defined in `.env` files or passed via command line.

## Creating Custom Templates

### Default Template

If no custom template is provided, YAGET uses `docker-compose.yml.tpl` in the root directory as the default. This template is designed for GitLab deployments.

### Docker Compose Templates

Create `docker-compose.yml.tpl` in your service directory:

```yaml
# templates/basic/gitlab/docker-compose.yml.tpl
services:
  ${SERVICE_NAME}:
    image: "gitlab/gitlab-ce:${GITLAB_VERSION}"
    container_name: "${CONTAINER_NAME}"
    hostname: "${HOSTNAME}"
    environment:
      GITLAB_OMNIBUS_CONFIG: "from_file('/etc/gitlab/gitlab.rb')"
    volumes:
      - "${CONFIG_PATH}/gitlab.rb:/etc/gitlab/gitlab.rb:ro"
      - "${SERVICE_DIR}/volumes/data:/var/opt/gitlab"
    networks:
      - "${NETWORK_NAME}"
    ports:
      - "80"  # Let Docker assign random port

networks:
  ${NETWORK_NAME}:
    external: true
```

### Configuration File Templates

Any configuration file can be templated:

```ruby
# templates/basic/gitlab/gitlab.rb.tpl
external_url '${EXTERNAL_URL}'
gitlab_rails['initial_root_password'] = '${GITLAB_ROOT_PASSWORD}'
gitlab_rails['gitlab_shell_ssh_port'] = ${SSH_PORT}
```

## Volume Convention

Templates must use bind mounts to `$SERVICE_DIR/volumes/` for data persistence:

```yaml
volumes:
  - "${SERVICE_DIR}/volumes/config:/etc/gitlab"
  - "${SERVICE_DIR}/volumes/logs:/var/log/gitlab"
  - "${SERVICE_DIR}/volumes/data:/var/opt/gitlab"
```

This ensures:
- All deployment data stays within the artifacts directory
- Data can be directly accessed from the host filesystem
- Cleanup is as simple as removing the artifacts directory
- Backups can be done by copying the artifacts directory

**Do not use Docker named volumes** - they won't be cleaned up properly.

## Environment Variables

### Loading Order

1. Default `.env` in YAGET root directory
2. Service-specific `.env` in service directory
3. Command line environment variables (highest precedence)

### Default Values

Because `envsubst` doesn't support `${VAR:-default}` syntax, use `.env` files for defaults:

```bash
# templates/basic/gitlab/.env
GITLAB_VERSION=latest
EXTERNAL_URL=http://gitlab.local
HTTP_PORT=80
GITLAB_ROOT_PASSWORD=changemeplease
```

### Command Line Override

```bash
GITLAB_VERSION=16.0.0 EXTERNAL_URL=https://test.local ./deploy.sh basic
```

## Template Examples

### Simple Service

```yaml
# templates/basic/redis/docker-compose.yml.tpl
services:
  ${SERVICE_NAME}:
    image: "redis:${REDIS_VERSION}"
    container_name: "${CONTAINER_NAME}"
    volumes:
      - "${SERVICE_DIR}/volumes/data:/data"
    networks:
      - "${NETWORK_NAME}"

networks:
  ${NETWORK_NAME}:
    external: true
```

### Service with Dependencies

```yaml
# templates/sso/gitlab/docker-compose.yml.tpl
services:
  ${SERVICE_NAME}:
    image: "gitlab/gitlab-ee:${GITLAB_VERSION}"
    container_name: "${CONTAINER_NAME}"
    environment:
      GITLAB_OMNIBUS_CONFIG: "from_file('/etc/gitlab/gitlab.rb')"
    volumes:
      - "${CONFIG_PATH}/gitlab.rb:/etc/gitlab/gitlab.rb:ro"
      - "${SERVICE_DIR}/volumes/data:/var/opt/gitlab"
    networks:
      - "${NETWORK_NAME}"

networks:
  ${NETWORK_NAME}:
    external: true
```

With corresponding `gitlab.rb.tpl`:
```ruby
# templates/sso/gitlab/gitlab.rb.tpl
external_url '${EXTERNAL_URL}'

# LDAP Configuration
gitlab_rails['ldap_enabled'] = true
gitlab_rails['ldap_servers'] = {
  'main' => {
    'label' => 'LDAP',
    'host' => '${DEPLOYMENT_NAME}-ldap',
    'port' => 389,
    'uid' => 'uid',
    'bind_dn' => '${LDAP_BIND_DN}',
    'password' => '${LDAP_PASSWORD}',
    'base' => '${LDAP_BASE}'
  }
}
```

## File Structure

Templates are organized under the `templates/` directory (or custom location via `YAGET_TEMPLATES_DIR`):

```
templates/
└── deployment-name/
    ├── .env                      # Deployment-wide defaults (optional)
    └── service-name/
        ├── .env                  # Service-specific defaults (optional)
        ├── docker-compose.yml.tpl # Docker Compose template
        ├── config.tpl            # Any config file template
        ├── pre-deploy.sh         # Pre-deployment script (optional)
        └── post-deploy.sh        # Post-deployment script (optional)
```

## Tips

1. **Keep templates simple** - Let Docker and the application handle complexity
2. **Use .env for defaults** - Don't hardcode values in templates
3. **Test with envsubst** - `envsubst < template.tpl` to see output
4. **Check required variables** - Document which variables must be set
5. **Avoid special characters** - Some characters in variable values may cause issues