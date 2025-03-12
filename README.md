# GitLab Test Environments

A collection of Docker Compose templates for quickly spinning up GitLab test environments to troubleshoot customer issues.

## Overview

This toolkit provides ready-to-use Docker Compose configurations for common GitLab testing scenarios. It's designed to help support engineers quickly reproduce and troubleshoot customer environments without complex setup.

## Features

- **Customer-Focused**: Use actual gitlab.rb configuration files, just like customers do
- **Quick Deployment**: Spin up working GitLab instances with a single command
- **Common Configurations**: Pre-built templates for typical customer setups
- **Customizable**: Easily adjust versions and configurations
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

# Deploy with a customer's configuration file
./deploy.sh base --config /path/to/customer/gitlab.rb

# Clean up when finished
./destroy.sh gitlab-base
```

### Important: Configure Local DNS

For a complete testing experience, add the GitLab hostname to your local hosts file:

```bash
# Add to /etc/hosts (Linux/macOS) or C:\Windows\System32\drivers\etc\hosts (Windows)
127.0.0.1 gitlab.local
```

This enables:
- Correct URL handling for callbacks and webhooks
- Email domain verification
- SSL certificate validation (when configured)
- Better simulation of a production environment

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
- A `config/gitlab.rb` file for GitLab configuration
- A `.env` file for basic Docker settings (ports, version)
- Docker Compose files for the service definitions

### Customizing GitLab Configuration

All GitLab configuration happens through the `gitlab.rb` file, just like in production:

1. **Use an existing template**: Each environment comes with a pre-configured gitlab.rb
   ```bash
   ./deploy.sh base
   ```

2. **Use a customer's configuration**:
   ```bash
   ./deploy.sh base --config /path/to/customer/gitlab.rb
   ```

3. **Modify a running deployment**:
   ```bash
   # Edit the configuration
   vi deployments/gitlab-base/config/gitlab.rb

   # Apply changes without restarting
   docker exec -it gitlab-base-gitlab gitlab-ctl reconfigure
   ```

## Detailed Usage

### Deploying an Environment

```bash
./deploy.sh <template-name> [options]

Options:
  -v, --version VERSION  Specify GitLab version (default: latest)
  -n, --name NAME        Custom deployment name (default: template name)
  -c, --config FILE      Custom gitlab.rb file
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
   # Deploy using the customer's configuration
   ./deploy.sh base --config customer-gitlab.rb --name customer-issue-123
   ```

2. **Experiment with Configuration**:
   ```bash
   # Edit the configuration
   vi deployments/customer-issue-123/config/gitlab.rb
   
   # Reconfigure GitLab to apply changes
   docker exec gitlab-base-gitlab gitlab-ctl reconfigure
   ```

3. **Clean Up**:
   ```bash
   ./destroy.sh customer-issue-123
   ```

## Extending and Customizing

To create a custom environment:

1. Create a new template directory:
   ```bash
   mkdir -p custom-setup/config
   ```

2. Add your gitlab.rb configuration:
   ```bash
   vi custom-setup/config/gitlab.rb
   ```

3. Copy a docker-compose.yml from an existing template:
   ```bash
   cp base/docker-compose.yml custom-setup/
   ```

4. Deploy your custom setup:
   ```bash
   ./deploy.sh custom-setup
   ```

## Troubleshooting

### Common Issues

1. **Port Conflicts**: If ports are already in use, edit the `.env` file to change the port mappings.

2. **Resource Constraints**: GitLab requires significant resources. On resource-limited systems, try:
   - Reducing Puma workers and Sidekiq concurrency in gitlab.rb
   - Disabling unnecessary services in gitlab.rb

3. **Startup Timeout**: GitLab may take several minutes to initialize. Check the logs:
   ```bash
   cd deployments/gitlab-base && docker compose logs -f gitlab
   ```

4. **Configuration Errors**: If GitLab fails to start, check for configuration errors:
   ```bash
   # Check logs for configuration errors
   docker compose logs gitlab | grep "Config"
   
   # Validate configuration (in a running container)
   docker exec gitlab-base-gitlab gitlab-ctl reconfigure
   ```

5. **URL/Domain Issues**: If you experience URL-related problems:
   - Ensure you've added the hostname to your `/etc/hosts` file
   - Make sure `external_url` in gitlab.rb matches the hostname
   - Check that port forwarding is working correctly

## Contributing

Contributions are welcome! If you have improvements or new templates:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request with your changes

## License

[MIT License](LICENSE)
