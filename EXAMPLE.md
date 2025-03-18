# Creating Your First GitLab Test Environment

This tutorial walks you through creating a complete GitLab test environment with multiple services.

## Creating a Geo Deployment Example

In this example, we'll create a GitLab Geo deployment with a primary and secondary node.

### Step 1: Set Up the Directory Structure

First, let's create the necessary directories:

```bash
# Create the deployment directory
mkdir -p gitlab-test-env/geo-deployment/primary
mkdir -p gitlab-test-env/geo-deployment/secondary
```

### Step 2: Configure the Primary Node

Create a gitlab.rb file for the primary node:

```bash
# Create gitlab.rb file
touch gitlab-test-env/geo-deployment/primary/gitlab.rb
```

Edit the `gitlab-test-env/geo-deployment/primary/gitlab.rb` file with the following content:

```ruby
# Primary Geo node configuration
external_url 'http://geo-deployment-primary.local'

# Enable Geo primary role
gitlab_rails['geo_node_name'] = 'geo-deployment-primary'
gitlab_rails['gitlab_shell_ssh_port'] = 2222
gitlab_rails['geo_primary_role'] = true

# Database settings
postgresql['enable'] = true
postgresql['listen_address'] = '*'
postgresql['port'] = 5432
postgresql['sql_user'] = 'gitlab'
postgresql['sql_password'] = 'gitlab'
postgresql['md5_auth_cidr_addresses'] = ['0.0.0.0/0']

# Redis settings
redis['enable'] = true
redis['bind'] = '0.0.0.0'

# Enable tracking database
geo_postgresql['enable'] = true
geo_postgresql['listen_address'] = '*'
```

### Step 3: Configure the Secondary Node

Create a gitlab.rb file for the secondary node:

```bash
# Create gitlab.rb file
touch gitlab-test-env/geo-deployment/secondary/gitlab.rb
```

Edit the `gitlab-test-env/geo-deployment/secondary/gitlab.rb` file with the following content:

```ruby
# Secondary Geo node configuration
external_url 'http://geo-deployment-secondary.local'

# Configure as secondary node
gitlab_rails['geo_node_name'] = 'geo-deployment-secondary'
gitlab_rails['gitlab_shell_ssh_port'] = 2223
gitlab_rails['geo_secondary_role'] = true

# PostgreSQL connection to primary
gitlab_rails['db_host'] = 'geo-deployment-primary'
gitlab_rails['db_port'] = 5432
gitlab_rails['db_username'] = 'gitlab'
gitlab_rails['db_password'] = 'gitlab'

# Redis connection to primary
gitlab_rails['redis_host'] = 'geo-deployment-primary'

# Tracking database settings
geo_postgresql['enable'] = true
geo_postgresql['listen_address'] = '*'
```

### Step 4: Create a Custom Docker Compose File for the Secondary Node

Since the secondary node needs custom port mappings, let's create a custom template file:

```bash
touch gitlab-test-env/geo-deployment/secondary/docker-compose.secondary.yml.template
```

Edit the `gitlab-test-env/geo-deployment/secondary/docker-compose.secondary.yml.template` file:

```yaml
version: '3.8'

services:
  secondary:
    ports:
      - "8081:80"  # Map secondary to a different port
      - "2223:22"  # Different SSH port
    depends_on:
      - primary    # Ensure primary starts first
```

### Step 5: Deploy the Environment

Now deploy the Geo environment:

```bash
./deploy.sh geo-deployment --version 15.11.3-ee.0
```

The script will:
1. Create a Docker network for the deployment
2. Discover the primary and secondary services
3. Deploy them with the appropriate configurations
4. Set up the container names as geo-deployment-primary and geo-deployment-secondary
5. Assign incremental port numbers to each service

### Step 6: Update Your Hosts File

Before you can access the services, you need to manually update your hosts file:

```bash
# Edit your hosts file with sudo
sudo nano /etc/hosts

# Add these entries:
127.0.0.1    geo-deployment-primary.local
127.0.0.1    geo-deployment-secondary.local
```

This allows you to access the services using their `.local` domain names from your host machine.

### Step 7: Set Up Geo Replication

After deployment, you need to set up Geo replication:

1. Access the primary node UI at http://localhost:80
2. Generate and retrieve a Geo token
3. Configure the secondary node with this token

```bash
# SSH into the primary node
docker exec -it geo-deployment-primary bash

# Generate Geo token and save it
gitlab-rails runner "puts Gitlab::Geo::GeoNodes.new.generate_token"
```

Use this token to register the secondary node.

### Step 8: Test the Deployment

You can now test the Geo deployment:

1. Create a project on the primary node
2. Wait for it to be replicated to the secondary
3. Verify the replication works correctly

### Step 9: Clean Up

When you're done testing, destroy the environment:

```bash
# To completely remove the environment:
./destroy.sh geo-deployment

# Or, to preserve data for future testing:
./destroy.sh geo-deployment --keep-data
```

## Creating a Custom Service

Let's say you want to add a specific service to another deployment:

### Step 1: Create the Service Directory

```bash
mkdir -p gitlab-test-env/custom-deployment/gitlab-pages
```

### Step 2: Configure the Service

Create a gitlab.rb file:

```bash
touch gitlab-test-env/custom-deployment/gitlab-pages/gitlab.rb
```

Edit the `gitlab-test-env/custom-deployment/gitlab-pages/gitlab.rb` file:

```ruby
# GitLab Pages configuration
external_url 'http://custom-deployment-gitlab-pages.local'

# Enable GitLab Pages
pages_external_url 'http://pages.example.com'
gitlab_pages['enable'] = true
gitlab_pages['access_control'] = true

# Other configurations
gitlab_rails['gitlab_shell_ssh_port'] = 2224
```

### Step 3: Create a Custom Docker Compose File

```bash
touch gitlab-test-env/custom-deployment/gitlab-pages/docker-compose.gitlab-pages.yml
```

Edit the `gitlab-test-env/custom-deployment/gitlab-pages/docker-compose.gitlab-pages.yml` file:

```yaml
version: '3.8'

services:
  gitlab-pages:
    ports:
      - "8082:80"
      - "2224:22"
      - "8090:8090"  # Pages-specific port
    environment:
      GITLAB_PAGES_ENABLED: "true"
```

### Step 4: Deploy and Test

```bash
./deploy.sh custom-deployment

# Remember to manually update your hosts file
sudo nano /etc/hosts
# Add: 127.0.0.1    custom-deployment-gitlab-pages.local
```

## Sharing Your Deployment

To share your deployment with team members:

1. Add all required files to your version control:
   ```bash
   git add gitlab-test-env/geo-deployment/
   git commit -m "Add Geo deployment configuration"
   git push origin main
   ```

2. Document the usage in a deployment-specific README:
   ```bash
   touch gitlab-test-env/geo-deployment/README.md
   ```

3. Include any special setup steps, environment variables or configuration notes in the README.

4. Your colleagues can now deploy the same environment:
   ```bash
   git clone https://your-repo-url/gitlab-test-env.git
   cd gitlab-test-env
   ./deploy.sh geo-deployment
   ```

By following these examples, you can create and share various testing environments for different GitLab configurations.