# YAGET (Yet Another GitLab Environment Tool)

A flexible Docker Compose-based system for deploying and managing multiple GitLab test environments.

## Features

- Deploy multiple isolated GitLab instances simultaneously
- Each deployment has its own network and volumes
- Automatic port assignment using Docker's built-in mechanism
- Configurable via custom templates and environment variables
- Post-deployment automation support
- Simple management with deployment and destruction scripts

## Requirements

- Docker and Docker Compose
- Bash shell environment
- envsubst utility (part of gettext package)

## Quick Start

1. Clone this repository
2. Create a deployment directory with at least one service
3. Run the deployment script

Example:

```bash
./deploy.sh basic-gitlab
```

To destroy a deployment:

```bash
./destroy.sh basic-gitlab
```

## Port Assignment

YAGET uses Docker's built-in port allocation system to automatically assign available ports on the host machine.

### Automatic Port Assignment

By default, the system lets Docker assign random available ports for HTTP, HTTPS, and SSH services:

```yaml
ports:
  - ":80"   # HTTP
  - ":443"  # HTTPS
  - ":22"   # SSH
```

The assigned ports are displayed in the deployment summary:

```
[2023-03-23 12:34:56] INFO: Exposed Ports:
[2023-03-23 12:34:56] INFO:   HTTP: 0.0.0.0:32768 -> 80/tcp
[2023-03-23 12:34:56] INFO:   HTTPS: 0.0.0.0:32769 -> 443/tcp
[2023-03-23 12:34:56] INFO:   SSH: 0.0.0.0:32770 -> 22/tcp
```

### Manual Port Assignment

You can manually specify ports by setting environment variables in a `.env` file:

```
HTTP_PORT=8080
HTTPS_PORT=8443
SSH_PORT=2222
```

Place this file in either:
- The root directory (affects all deployments)
- The deployment directory (affects all services in that deployment)
- The service directory (affects only that specific service)

## Deployment Structure

A deployment consists of:

```
deployment-name/
├── service1/
│   ├── gitlab.rb              # GitLab configuration
│   ├── .env                   # Optional environment variables
│   ├── post-deploy.sh         # Optional post-deployment script
│   └── docker-compose.service1.template  # Optional custom template
└── service2/
    └── ...
```

## Custom Templates

Create a file named `docker-compose.service-name.template` in the service directory to override the default template.

For more details, see [TEMPLATES.md](TEMPLATES.md).

## Example Deployments

See [EXAMPLE.md](EXAMPLE.md) for example deployments and configurations.

## Management Scripts

### deploy.sh

```bash
./deploy.sh <deployment_name> [--version <gitlab_version>]
```

Options:
- `--version <version>`: Specify GitLab version (default: latest)
- `--help`: Display help information

### destroy.sh

```bash
./destroy.sh <deployment_name> [--keep-data]
```

Options:
- `--keep-data`: Preserve data volumes after destroying services
- `--help`: Display help information

## Configuration Reference

### gitlab.rb

Each GitLab instance should have a `gitlab.rb` file that configures the GitLab instance.
Other services don't need it, but YAGET will warn you about it anyway.

Example:

```ruby
external_url 'http://my-gitlab.local'
gitlab_rails['gitlab_shell_ssh_port'] = 2222
```

### Environment Variables

These variables can be set in `.env` files:

| Variable | Description | Example |
|----------|-------------|---------|
| `GITLAB_VERSION` | GitLab version | `15.11.3-ee.0` |
| `HTTP_PORT` | Host port for HTTP | `8080` |
| `HTTPS_PORT` | Host port for HTTPS | `8443` |
| `SSH_PORT` | Host port for SSH | `2222` |

_Only `$VAR` and `${VAR}` works with `envsubst`. Other syntax will be treated as literal strings_

## Post-Deployment Automation

Create an executable `post-deploy.sh` script in a service directory to run commands after deployment.
