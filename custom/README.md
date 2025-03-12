# Custom GitLab Environment Template

This directory provides a starting point for creating your own custom GitLab test environments. Use this template when you need to create a configuration that isn't covered by the standard templates.

## Getting Started

1. Create your own gitlab.rb configuration file:
   ```bash
   mkdir -p config
   touch config/gitlab.rb
   ```

2. Edit the configuration to meet your specific needs:
   ```bash
   vi config/gitlab.rb
   ```

3. Deploy your custom environment:
   ```bash
   ../deploy.sh custom --name my-custom-setup
   ```

## Customizing the Environment

### Adding Services

You can add additional services to the `docker-compose.yml` file. For example, to add LDAP:

```yaml
services:
  # ...existing GitLab service...

  ldap:
    image: osixia/openldap:1.5.0
    container_name: ${DEPLOYMENT_NAME:-gitlab-custom}-ldap
    hostname: 'ldap.local'
    # Add your LDAP configuration here...
```

### Extending with Scripts

Create pre-deploy or post-deploy scripts to automate setup steps:

```bash
# Create a post-deployment script
touch post-deploy.sh
chmod +x post-deploy.sh
```

### Using Customer Configurations

To test with a customer's configuration:

1. Copy their gitlab.rb file into your config directory:
   ```bash
   cp /path/to/customer/gitlab.rb config/
   ```

2. Deploy the environment:
   ```bash
   ../deploy.sh custom --name customer-case-123
   ```

## Examples

### High Availability Setup

```ruby
# config/gitlab.rb
external_url 'http://gitlab.local'
postgresql['enable'] = false
gitlab_rails['db_host'] = 'postgres'
gitlab_rails['db_password'] = 'password'
redis['enable'] = false
gitlab_rails['redis_host'] = 'redis'
```

### Custom NGINX Configuration

```ruby
# config/gitlab.rb
nginx['custom_gitlab_server_config'] = "location ^~ /custom-endpoint/ { proxy_pass http://custom-service:8080/; }"
```
