# GitLab Testing Environment System

A flexible system for GitLab support engineers to quickly set up, manage, and share testing environments without hardcoded configurations.

## Table of Contents

- [Overview](#overview)
- [Directory Structure](#directory-structure)
- [Installation](#installation)
- [Usage](#usage)
  - [Deploying Environments](#deploying-environments)
  - [Destroying Environments](#destroying-environments)
  - [Accessing Services](#accessing-services)
- [Creating New Deployments](#creating-new-deployments)
  - [Adding New Services](#adding-new-services)
  - [Customizing Service Configuration](#customizing-service-configuration)
- [Sharing Environments](#sharing-environments)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Overview

This system provides a set of scripts to manage GitLab testing environments with these key features:

- **Dynamic discovery** of services without hardcoded values
- **Flexible configuration** with service-specific overrides
- **Network isolation** for each deployment
- **Consistent naming** with deployment_name-service_name pattern
- **Version control** with GitLab version selection
- **Data persistence options** when destroying environments

## Directory Structure

```
gitlab-test-env/
  deploy.sh                # Deployment script
  destroy.sh               # Teardown script
  docker-compose.yml       # Base configuration template
  deployment1-name/        # A deployment environment
    service1-name/         # A service within the deployment
      docker-compose.service1-name.yml  # Optional custom compose file
      gitlab.rb            # Service-specific GitLab configuration
    service2-name/
      gitlab.rb
  deployment2-name/
    # More services...
```

## Installation

1. Clone this repository:

```bash
git clone https://your-repo-url/gitlab-test-env.git
cd gitlab-test-env
```

2. Install dependencies:

```bash
# Check and install required dependencies
./install_dependencies.sh
```

This script will verify you have:
- Docker
- Docker Compose V2
- envsubst (part of gettext)

3. Make the scripts executable (if not already):

```bash
chmod +x deploy.sh destroy.sh
```

## Usage

### Deploying Environments

To deploy a testing environment:

```bash
./deploy.sh <deployment_name> [--version <gitlab_version>]
```

Examples:

```bash
# Deploy using the latest GitLab version
./deploy.sh deployment1-name

# Deploy with a specific GitLab version
./deploy.sh deployment1-name --version 15.11.3-ce.0
```

The script will:
1. Create a dedicated Docker network for the deployment
2. Discover all services within the deployment directory
3. Deploy each service using the appropriate configuration
4. Mount service-specific gitlab.rb files

### Destroying Environments

To tear down a testing environment:

```bash
./destroy.sh <deployment_name> [--keep-data]
```

Examples:

```bash
# Destroy and remove all data
./destroy.sh deployment1-name

# Destroy but preserve data volumes for future use
./destroy.sh deployment1-name --keep-data
```

The script will:
1. Stop all services in reverse order
2. Remove containers and (optionally) volumes
3. Remove the Docker network

### Accessing Services

Once deployed, services are accessible:

- Each service has a container name of `<deployment_name>-<service_name>` and hostname of `<deployment_name>-<service_name>.local`
- Services within the same deployment can communicate with each other using these hostnames
- Default ports are automatically incremented for each service in a deployment to avoid conflicts
- You must manually update your `/etc/hosts` file to access the services by hostname from your host machine

To update your `/etc/hosts` file:

```bash
# Manually add entries to /etc/hosts (requires sudo)
sudo nano /etc/hosts

# Add lines like:
127.0.0.1    deployment1-service1.local
127.0.0.1    deployment1-service2.local
```

## Creating New Deployments

To create a new deployment environment:

1. Create a new directory under the gitlab-test-env directory:

```bash
mkdir -p gitlab-test-env/my-new-deployment
```

2. Add service directories and their configurations:

```bash
mkdir -p gitlab-test-env/my-new-deployment/gitlab-web
```

3. Create the required gitlab.rb file:

```bash
touch gitlab-test-env/my-new-deployment/gitlab-web/gitlab.rb
```

4. Edit the gitlab.rb file with appropriate configuration

### Adding New Services

To add a new service to an existing deployment:

1. Create a new service directory:

```bash
mkdir -p gitlab-test-env/existing-deployment/new-service
```

2. Create the required gitlab.rb file:

```bash
touch gitlab-test-env/existing-deployment/new-service/gitlab.rb
```

3. (Optional) Create a custom docker-compose file if needed:

```bash
touch gitlab-test-env/existing-deployment/new-service/docker-compose.new-service.yml
```

### Customizing Service Configuration

1. **Basic Configuration** - Edit the gitlab.rb file for your service:

```ruby
# Example gitlab.rb for a service
external_url 'http://deployment-name-service-name.local'
gitlab_rails['gitlab_shell_ssh_port'] = 2222
# More configuration...
```

2. **Advanced Configuration** - Create a custom docker-compose file:

```yaml
version: '3.8'

services:
  service-name:
    # Inherit from the base compose file
    extends:
      file: ../../docker-compose.yml
      service: ${SERVICE_NAME}
    
    # Add or override settings
    ports:
      - "8080:80"
      - "2222:22"
    
    environment:
      ADDITIONAL_ENV: "value"
```

## Sharing Environments

To share your testing environment with colleagues:

1. **Document your deployment**: Create a README in your deployment directory explaining:
   - Purpose of the deployment
   - Services included and their configurations
   - Any special requirements

2. **Share the directory**: Either through:
   - Version control (Git)
   - Container registry (for pre-built images)
   - Deployment scripts (for cloud environments)

3. **Provide deployment instructions**:

```bash
# Clone the repository (if using Git)
git clone https://your-repo-url/gitlab-test-env.git

# Deploy the environment
cd gitlab-test-env
./deploy.sh your-deployment-name --version 15.11.3-ce.0
```

## Best Practices

1. **Naming Conventions**:
   - Use descriptive names for deployments and services
   - Follow kebab-case for directory names (e.g., `ha-cluster`, `geo-setup`)

2. **Configuration Management**:
   - Keep gitlab.rb files focused and minimal
   - Document the purpose of each setting with comments
   - Use environment variables for sensitive information

3. **Resource Management**:
   - Destroy unused environments to free resources
   - Use the `--keep-data` flag if you plan to redeploy later
   - Consider resource limits in docker-compose files for complex setups

4. **Testing and Development**:
   - Create separate deployments for different test scenarios
   - Document any special steps needed for your scenario

## Troubleshooting

### Common Issues

1. **Service fails to start**:
   - Check the logs: `docker logs <deployment_name>-<service_name>`
   - Verify the gitlab.rb configuration
   - Ensure ports are not already in use

2. **Services cannot communicate**:
   - Verify all services are on the same network: `docker network inspect <deployment_name>-network`
   - Check hostname resolution: `docker exec <container_name> ping <other_container_name>`

3. **Deploy script fails**:
   - Ensure all directories exist
   - Check permissions on gitlab.rb files
   - Verify Docker and Docker Compose are properly installed

### Getting Logs

```bash
# Get logs for a specific service
docker logs <deployment_name>-<service_name>

# Follow logs in real-time
docker logs -f <deployment_name>-<service_name>
```

### Accessing Containers

```bash
# Open a shell in a container
docker exec -it <deployment_name>-<service_name> bash
```
