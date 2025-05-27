# YAGET (Yet Another GitLab Environment Tool)

A flexible Docker Compose-based system for deploying and managing multiple GitLab test environments.

## Features

- Deploy multiple isolated GitLab instances simultaneously
- Each deployment has its own network and volumes
- Automatic port assignment using Docker's built-in mechanism
- Template-based configuration with environment variable substitution
- Pre and post-deployment script support
- All deployment artifacts and data stored in a single directory tree
- Simple management with deployment and destruction scripts

## Requirements

- Docker and Docker Compose
- Bash shell environment
- envsubst utility (part of gettext package)

## Quick Start

1. Clone this repository: `git clone git@gitlab.com:yaker-gitlab/yaget.git`
2. Change into that directory: `cd ./yaget`
3. Run the deployment script: 
   * For a basic GitLab instance: `./deploy.sh basic`
   * With specific version: `GITLAB_VERSION=17.11.1-ee.0 ./deploy.sh basic`
   * For GitLab with LDAP: `./deploy.sh sso`

To destroy a deployment: `./destroy.sh basic`

## Directory Structure

### Source Structure

```
yaget/
├── lib/                        # Library functions
│   ├── common.sh              # Logging and utilities
│   ├── docker.sh              # Docker operations
│   ├── template.sh            # Template processing
│   └── deployment.sh          # Deployment orchestration
├── deploy.sh                   # Main deployment script
├── destroy.sh                  # Cleanup script
├── docker-compose.yml.tpl      # Default template
└── templates/                  # Deployment templates (see Template Organization)
    └── deployment-name/
        ├── .env               # Deployment-wide variables
        └── service-name/
            ├── .env           # Service-specific variables
            ├── gitlab.rb      # GitLab configuration
            ├── pre-deploy.sh  # Pre-deployment script
            ├── post-deploy.sh # Post-deployment script
            └── *.tpl          # Any .tpl file gets processed
```

### Generated Artifacts

After deployment, all generated files and data are stored in the `artifacts/` directory:

```
artifacts/
└── deployment-name/
    └── service-name/
        ├── docker-compose.yml  # Generated from template
        ├── gitlab.rb           # Copied configuration (used by container)
        └── volumes/            # Container data (bind mounted)
            ├── config/         # Application configuration
            ├── logs/           # Application logs
            └── data/           # Application data
```

All container data is stored as bind mounts within the artifacts directory, making it easy to:
- Browse logs and data directly from the host
- Back up entire deployments by copying the artifacts directory
- Clean up deployments completely by removing the artifacts directory

## Template Organization

### Default Templates Directory

YAGET looks for templates in the `templates/` directory by default:

```
yaget/
├── templates/
│   ├── basic/          # Basic GitLab deployment
│   ├── sso/           # GitLab with LDAP
│   └── custom/        # Your custom deployments
└── ...
```

### Using External Templates

You can override the templates directory using `YAGET_TEMPLATES_DIR`:

```bash
# Use templates from another location
YAGET_TEMPLATES_DIR=/shared/gitlab-templates ./deploy.sh sso

# Or export for all commands
export YAGET_TEMPLATES_DIR=~/my-yaget-templates
./deploy.sh basic
```

### Organizing Template Collections

For better organization, you can maintain templates in separate repositories:

```bash
# Clone YAGET
git clone https://github.com/your-org/yaget.git
cd yaget

# Option 1: Clone templates into default location
git clone https://github.com/your-org/yaget-templates.git templates

# Option 2: Clone elsewhere and use environment variable
git clone https://github.com/your-org/yaget-templates.git ~/yaget-templates
export YAGET_TEMPLATES_DIR=~/yaget-templates

# Option 3: Mix templates from multiple sources using symlinks
mkdir -p templates
ln -s ~/gitlab-templates/basic templates/basic
ln -s ~/company-templates/production templates/production
ln -s /shared/team-templates/debugging templates/debugging

# Now you can use templates from different sources
./deploy.sh basic       # From ~/gitlab-templates
./deploy.sh production  # From ~/company-templates
./deploy.sh debugging   # From /shared/team-templates
```

This approach:
- Keeps YAGET core small and fast
- Allows sharing templates without modifying YAGET
- Enables private template collections
- Makes templates easily updatable
- Lets you mix templates from multiple sources

## Templates

YAGET uses a simple template system:
- Any file ending in `.tpl` is processed with `envsubst`
- The `.tpl` suffix is removed from the output filename
- All other files are copied as-is

Examples:
- `gitlab.rb.tpl` → `gitlab.rb` (with variables substituted)
- `docker-compose.yml.tpl` → `docker-compose.yml` 
- `prometheus.yml.tpl` → `prometheus.yml`

## Environment Variables

### Variable Precedence

Variables are loaded in this order (later overrides earlier):
1. Default `.env` file in YAGET root directory
2. Service-specific `.env` files
3. Environment variables passed on command line

Example:
```bash
# Uses all defaults
./deploy.sh my-deployment

# Override specific variables
GITLAB_VERSION=16.0.0 HTTP_PORT=8080 ./deploy.sh my-deployment
```

### Available Variables in Templates

| Variable | Description | Example |
|----------|-------------|---------|
| `$DEPLOYMENT_NAME` | Name of the deployment | `my-deployment` |
| `$SERVICE_NAME` | Name of the service | `gitlab` |
| `$CONTAINER_NAME` | Full container name | `my-deployment-gitlab` |
| `$HOSTNAME` | Container hostname | `my-deployment-gitlab.local` |
| `$NETWORK_NAME` | Docker network name | `my-deployment-network` |
| `$SERVICE_DIR` | Path to service in artifacts | `/path/to/artifacts/my-deployment/gitlab` |
| `$CONFIG_PATH` | Alias for SERVICE_DIR | `/path/to/artifacts/my-deployment/gitlab` |
| `$TEMPLATE_DIR` | Path to template directory | `/path/to/yaget/my-deployment` |

### Special Variables

- `YAGET_ARTIFACTS_ROOT` - Override artifacts directory location (default: `./artifacts`)
- `GITLAB_VERSION` - GitLab Docker image version (default: `latest`)

## Pre and Post Deployment Scripts

Services can include executable scripts that run during deployment:

- `pre-deploy.sh` - Runs before the service is deployed
- `post-deploy.sh` - Runs after the service is started

These scripts receive environment variables:
- `DEPLOYMENT_NAME`
- `SERVICE_NAME` 
- `CONTAINER_NAME`

Example post-deploy.sh:
```bash
#!/bin/bash
# Wait for GitLab to be ready
docker exec $CONTAINER_NAME gitlab-ctl status
```

## Management Commands

### deploy.sh

```bash
./deploy.sh <deployment_name>
```

Environment variables can be passed directly:
```bash
GITLAB_VERSION=15.11.3-ee.0 ./deploy.sh my-deployment
```

### destroy.sh

```bash
./destroy.sh <deployment_name> [--keep-data]
```

Options:
- `--keep-data`: Preserve artifacts directory (including all data)

## Working with Deployments

### Modifying Configurations

After deployment, you can modify configuration files in the artifacts directory:

```bash
# Edit GitLab configuration
vim artifacts/my-deployment/gitlab/gitlab.rb

# Restart the service to apply changes
docker compose -f artifacts/my-deployment/gitlab/docker-compose.yml restart

# Reset to original configuration
./deploy.sh my-deployment  # Overwrites all changes with source files
```

### Direct Docker Compose Access

You can manage deployments directly using the generated compose files:

```bash
cd artifacts/my-deployment/gitlab
docker compose up -d
docker compose logs -f
docker compose down
```

### Accessing Data

Since all volumes are bind mounted, you can directly access container data:

```bash
# View GitLab logs
tail -f artifacts/my-deployment/gitlab/volumes/logs/gitlab-rails/production.log

# Browse GitLab configuration
ls artifacts/my-deployment/gitlab/volumes/config/

# Check disk usage
du -sh artifacts/my-deployment/*/volumes/
```

## GitLab Initial Root Password

After deploying GitLab, get the initial root password:

```bash
docker exec -it <deployment-name>-gitlab grep 'Password: ' /etc/gitlab/initial_root_password

# Example for 'basic' deployment:
docker exec -it basic-gitlab grep 'Password: ' /etc/gitlab/initial_root_password
```

## Example Deployment

See [EXAMPLE.md](EXAMPLE.md) for complete deployment examples.

## Template Reference

See [TEMPLATES.md](TEMPLATES.md) for detailed template documentation.