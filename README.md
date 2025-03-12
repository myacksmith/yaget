# GitLab Compose
## GitLab Test Environments Using Docker Compose

A collection of Docker Compose templates for quickly spinning up GitLab test environments to troubleshoot customer issues.

## Overview

This toolkit provides ready-to-use Docker Compose configurations for common GitLab testing scenarios. It's designed to help support engineers quickly reproduce and troubleshoot customer environments without complex setup.

## Features

- **Quick Deployment**: Spin up working GitLab instances with a single command
- **Common Configurations**: Pre-built templates for typical customer setups
- **Customizable**: Easily adjust versions and settings via environment variables
- **Resource Efficient**: Optimized for development/testing environments
- **Cleanup Tools**: Simple commands to tear down environments when done

## Prerequisites

- Docker and Docker Compose installed
- Basic understanding of GitLab administration
- Sufficient system resources (4+ CPU cores, 8GB+ RAM recommended)

## Quick Start

To deploy a basic GitLab instance:

```bash
# Make the scripts executable
chmod +x deploy.sh destroy.sh

# Deploy a standard GitLab EE instance
./deploy.sh base

# Deploy with LDAP authentication
./deploy.sh ldap

# Deploy a specific GitLab version
./deploy.sh base --version 15.11.3-ee.0

# Clean up when finished
./destroy.sh gitlab-base
```

## Available Templates

| Template | Description | Features |
|----------|-------------|----------|
| `base` | Standard GitLab EE | Basic instance with default settings |
| `ldap` | LDAP Authentication | GitLab with OpenLDAP and sample users |
| `gitaly-cluster` | Gitaly Cluster | Separate Gitaly nodes configuration |
| `geo` | Geo Replication | Primary and secondary Geo nodes |
| `runners` | CI/CD | GitLab with pre-configured runners |
| `external-db` | External PostgreSQL | GitLab with external database |
| `custom` | Template for custom configs | Starting point for custom setups |

## Configuration

Each template includes:
- A `.env` file for customizing basic settings
- Docker Compose files with the environment setup
- README with template-specific instructions

You can customize:
- GitLab version
- Port mappings
- Configuration options
- Resource limits

## Detailed Usage

### Deploying an Environment

```bash
./deploy.sh <template-name> [options]

Options:
  -v, --version VERSION  Specify GitLab version (default: latest)
  -n, --name NAME        Custom deployment name (default: template name)
  -h, --help             Show help information
```

### Destroying an Environment

```bash
./destroy.sh <deployment-name> [options]

Options:
  -f, --force            Skip confirmation prompt
  -k, --keep-data        Keep volumes (don't remove data)
  -h, --help             Show help information
```

## Testing Workflows

1. **Reproduce Customer Issue**:
   ```bash
   ./deploy.sh ldap --version 15.9.0-ee.0 --name customer-issue-123
   ```

2. **Experiment with Configuration**:
   - Modify the GitLab configuration in the deployment's `.env` file
   - Restart the containers with `docker-compose restart`

3. **Clean Up**:
   ```bash
   ./destroy.sh customer-issue-123
   ```

## Extending and Customizing

To create a custom environment:

1. Copy an existing template to a new directory:
   ```bash
   cp -r base custom-setup
   ```

2. Modify the Docker Compose file and configuration
3. Deploy with:
   ```bash
   ./deploy.sh custom-setup
   ```

## Troubleshooting

### Common Issues

1. **Port Conflicts**: If ports are already in use, edit the `.env` file to change the port mappings.

2. **Resource Constraints**: GitLab requires significant resources. On resource-limited systems, try:
   - Reducing Puma workers and Sidekiq concurrency in GitLab config
   - Disabling unnecessary services

3. **Startup Timeout**: GitLab may take several minutes to initialize. Check the logs:
   ```bash
   cd deployments/gitlab-base && docker-compose logs -f gitlab
   ```

## Contributing

Contributions are welcome! If you have improvements or new templates:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request with your changes

## License

[MIT License](LICENSE)
