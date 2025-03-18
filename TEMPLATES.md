# Creating Custom Templates

This guide explains how to create custom templates for your GitLab services.

## Template Variables

The following variables are available in templates:

| Variable | Description | Example Value |
|----------|-------------|--------------|
| `$SERVICE_NAME` | Name of the service | `gitlab` |
| `$CONTAINER_NAME` | Full container name | `deployment-name-gitlab` |
| `$DEPLOYMENT_NAME` | Name of the deployment | `deployment-name` |
| `$NETWORK_NAME` | Docker network name | `deployment-name-network` |
| `$CONFIG_PATH` | Path to configuration file | `/path/to/gitlab.rb` |
| `$GITLAB_VERSION` | GitLab version | `15.11.3-ce.0` |
| `$HTTP_PORT` | HTTP port (incremental) | `80` |
| `$HTTPS_PORT` | HTTPS port (incremental) | `443` |
| `$SSH_PORT` | SSH port (incremental) | `2222` |

## Template Example

Create a file named `docker-compose.service-name.yml.template` in your service directory.

Here's a basic example for a GitLab service with customized ports:

```yaml
version: '3.8'

services:
  $SERVICE_NAME:
    image: "gitlab/gitlab-ee:${GITLAB_VERSION:-latest}"
    container_name: "$CONTAINER_NAME"
    hostname: "$CONTAINER_NAME.local"
    restart: unless-stopped
    environment:
      GITLAB_OMNIBUS_CONFIG: "from_file('/etc/gitlab/gitlab.rb')"
    volumes:
      - "$CONFIG_PATH:/etc/gitlab/gitlab.rb:ro"
      - "$DEPLOYMENT_NAME-$SERVICE_NAME-config:/etc/gitlab"
      - "$DEPLOYMENT_NAME-$SERVICE_NAME-logs:/var/log/gitlab"
      - "$DEPLOYMENT_NAME-$SERVICE_NAME-data:/var/opt/gitlab"
    networks:
      - "$NETWORK_NAME"
    # Custom ports configuration
    ports:
      - "9080:80"  # Custom HTTP port
      - "9443:443" # Custom HTTPS port
      - "${SSH_PORT:-2222}:22"  # Use incremental SSH port

volumes:
  $DEPLOYMENT_NAME-$SERVICE_NAME-config:
    name: "$DEPLOYMENT_NAME-$SERVICE_NAME-logs"
  $DEPLOYMENT_NAME-$SERVICE_NAME-data:
    name: "$DEPLOYMENT_NAME-$SERVICE_NAME-data"

networks:
  $NETWORK_NAME:
    external: true
```

## Advanced Template Examples

### 1. GitLab Runner Service

This template is designed for GitLab Runner services:

```yaml
version: '3.8'

services:
  $SERVICE_NAME:
    image: "gitlab/gitlab-runner:${GITLAB_VERSION:-latest}"
    container_name: "$CONTAINER_NAME"
    hostname: "$CONTAINER_NAME.local"
    restart: unless-stopped
    volumes:
      - "$CONFIG_PATH:/etc/gitlab-runner/config.toml:ro"
      - "/var/run/docker.sock:/var/run/docker.sock"
      - "$DEPLOYMENT_NAME-$SERVICE_NAME-data:/etc/gitlab-runner"
    networks:
      - "$NETWORK_NAME"
    environment:
      - REGISTER_NON_INTERACTIVE=true

volumes:
  $DEPLOYMENT_NAME-$SERVICE_NAME-data:
    name: "$DEPLOYMENT_NAME-$SERVICE_NAME-data"

networks:
  $NETWORK_NAME:
    external: true
```

### 2. LDAP Service

This template sets up an LDAP server that can integrate with GitLab:

```yaml
version: '3.8'

services:
  $SERVICE_NAME:
    image: "osixia/openldap:1.5.0"
    container_name: "$CONTAINER_NAME"
    hostname: "$CONTAINER_NAME.local"
    restart: unless-stopped
    environment:
      - LDAP_ORGANISATION="Example Inc."
      - LDAP_DOMAIN=example.org
      - LDAP_ADMIN_PASSWORD=admin
    volumes:
      - "$DEPLOYMENT_NAME-$SERVICE_NAME-data:/var/lib/ldap"
      - "$DEPLOYMENT_NAME-$SERVICE_NAME-config:/etc/ldap/slapd.d"
      - "$CONFIG_PATH:/container/service/slapd/assets/config/bootstrap/ldif/custom"
    networks:
      - "$NETWORK_NAME"
    ports:
      - "389:389"
      - "636:636"

volumes:
  $DEPLOYMENT_NAME-$SERVICE_NAME-data:
    name: "$DEPLOYMENT_NAME-$SERVICE_NAME-data"
  $DEPLOYMENT_NAME-$SERVICE_NAME-config:
    name: "$DEPLOYMENT_NAME-$SERVICE_NAME-config"

networks:
  $NETWORK_NAME:
    external: true
```

## Template Syntax Tips

1. **Default Values**: Use the `${VARIABLE:-default}` syntax to provide default values:
   ```yaml
   image: "gitlab/gitlab-ee:${GITLAB_VERSION:-latest}"
   ```

2. **Variable References**: For proper variable substitution, use:
   - `$VARIABLE` for simple variables
   - `${VARIABLE}` when followed by text or for default values

3. **Escaping Dollar Signs**: If you need a literal dollar sign in your template, double it:
   ```yaml
   # This will result in a single $ in the output
   literal_dollar: "$"
   ```

4. **Debugging Templates**: To see what a rendered template looks like without deploying:
   ```bash
   # Export necessary variables
   export SERVICE_NAME=gitlab
   export DEPLOYMENT_NAME=test
   # ... other variables
   
   # Render template to stdout
   envsubst < your-template.yml.template
   ```

## Best Practices

1. **Keep Templates Focused**: Each template should serve a specific purpose
2. **Comment Your Templates**: Add comments explaining custom configurations
3. **Version in Source Control**: Keep your templates in version control
4. **Validate Before Deployment**: Test templates with `envsubst` before using them
5. **Share Common Patterns**: Create a library of reusable templates for common service types-$SERVICE_NAME-config"
  $DEPLOYMENT_NAME-$SERVICE_NAME-logs:
    name: "$DEPLOYMENT_NAME