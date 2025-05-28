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

# Access GitLab
# Check the deployment output for the actual port

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

## What You'll See

```
=== Configuration ===
Deployment: basic
Network: basic-network
Templates: /home/user/yaget/templates/basic
Artifacts: /home/user/yaget/artifacts/basic

=== Deploying Services ===

[1/1] gitlab
  Environment:
    From ./.env:
      GITLAB_VERSION=latest
  
  Processing: /home/user/yaget/templates/basic/gitlab -> /home/user/yaget/artifacts/basic/gitlab
  Image: gitlab/gitlab-ee:latest
  Container: basic-gitlab
  Hostname: basic-gitlab.local
  ✓ Templates processed
  ✓ Container started
  ✓ Ports:
    80 → localhost:32768
    443 → localhost:32769
    22 → localhost:32770
```

The deployment shows:
- Where variables come from (which .env file)
- All exposed ports with localhost URLs
- Container names and hostnames
- Absolute paths for debugging

## Common Tasks

### Deploy with custom version
```bash
GITLAB_VERSION=16.0.0-ee.0 ./deploy.sh basic
```

### Use external templates
```bash
YAGET_TEMPLATES_DIR=/path/to/templates ./deploy.sh custom
```

### Keep data when destroying
```bash
./destroy.sh basic --keep-data
```

## See Also

- [TEMPLATES.md](TEMPLATES.md) - Template reference
- [EXAMPLES.md](EXAMPLES.md) - Deployment examples
