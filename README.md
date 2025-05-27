# YAGET (Yet Another GitLab Environment Tool)

Deploy multiple GitLab test environments using Docker Compose.

## Quick Start

```bash
# Clone and deploy
git clone <repo-url> yaget
cd yaget
./deploy.sh basic

# Get root password
docker exec -it basic-gitlab grep 'Password:' /etc/gitlab/initial_root_password

# Destroy when done
./destroy.sh basic
```

## How It Works

1. Templates in `templates/<deployment-name>/` define services
2. `deploy.sh` processes templates and starts containers
3. All data goes to `artifacts/<deployment-name>/`
4. Each deployment gets its own Docker network

## Directory Structure

```
yaget/
├── deploy.sh                   # Deploy environments
├── destroy.sh                  # Clean up deployments
├── templates/                  # Deployment templates
│   ├── basic/                  # Simple GitLab
│   └── sso/                    # GitLab + LDAP
└── artifacts/                  # Generated files and data (git-ignored)
    └── <deployment-name>/
        └── <service-name>/
            ├── docker-compose.yml
            ├── *.config-files
            └── volumes/        # Container data
```

## Templates

Templates use environment variables for configuration. Set them via:
- `.env` files in template directories
- Command line: `VAR=value ./deploy.sh name`

Files ending in `.tpl` are processed with environment substitution.

Available variables:
- `$DEPLOYMENT_NAME` - Your deployment name
- `$SERVICE_NAME` - Service name (e.g., gitlab, ldap)
- `$CONTAINER_NAME` - Full container name
- `$SERVICE_DIR` - Path to service in artifacts
- Plus any variables your templates require

## Common Tasks

### Deploy with custom version
```bash
GITLAB_VERSION=16.0.0-ee.0 ./deploy.sh basic
```

### Use external templates
```bash
YAGET_TEMPLATES_DIR=/path/to/templates ./deploy.sh custom
```

### Edit configuration
```bash
# In container (temporary)
docker exec -it basic-gitlab vi /etc/gitlab/gitlab.rb
docker exec basic-gitlab gitlab-ctl reconfigure

# On host (permanent)
vim templates/basic/gitlab/gitlab.rb
./deploy.sh basic
```

### Add a license
Add `gitlab-license.txt` to your template directory and mount it:
```yaml
volumes:
  - "${CONFIG_PATH}/gitlab-license.txt:/etc/gitlab/gitlab-license.txt"
```

## Pre/Post Scripts

- `pre-deploy.sh` - Runs before container starts
- `post-deploy.sh` - Runs after container starts

Both receive: `$DEPLOYMENT_NAME`, `$SERVICE_NAME`, `$CONTAINER_NAME`

## See Also

- [TEMPLATES.md](TEMPLATES.md) - Template reference
- [EXAMPLES.md](EXAMPLES.md) - Deployment examples