# GitLab with Geo Replication

This template sets up a GitLab Geo environment with primary and secondary nodes. Geo provides a complete replica of your GitLab instance that can be used for disaster recovery or to distribute read load.

## Features

- GitLab Enterprise Edition with Geo configuration
- Primary and secondary nodes
- Automatic replication of repositories and database
- Separate ports for each node

## Quick Deploy

From the main project directory:

```bash
./deploy.sh geo
```

Or with a specific version:

```bash
./deploy.sh geo --version 15.11.3-ee.0
```

## Configuration Options

Edit the `.env` file to customize the deployment:

| Variable | Description | Default |
|----------|-------------|---------|
| `DEPLOYMENT_NAME` | Name for the deployment | `gitlab-geo` |
| `GITLAB_IMAGE` | GitLab Docker image | `gitlab/gitlab-ee` |
| `GITLAB_VERSION` | GitLab version tag | `latest` |
| `PRIMARY_HTTP_PORT` | Primary HTTP port | `8080` |
| `PRIMARY_HTTPS_PORT` | Primary HTTPS port | `8443` |
| `PRIMARY_SSH_PORT` | Primary SSH port | `2222` |
| `SECONDARY_HTTP_PORT` | Secondary HTTP port | `8081` |
| `SECONDARY_HTTPS_PORT` | Secondary HTTPS port | `8444` |
| `SECONDARY_SSH_PORT` | Secondary SSH port | `2223` |

## Architecture

The setup consists of two main components:

1. **Primary Node**: The main GitLab instance where all write operations occur
2. **Secondary Node**: A replica that syncs data from the primary (read-only for most operations)

## Accessing GitLab

### Primary Node
- Web UI: http://gitlab.local:8080 (or the PRIMARY_HTTP_PORT you configured)
- SSH: ssh://gitlab.local:2222 (or the PRIMARY_SSH_PORT you configured)

### Secondary Node
- Web UI: http://gitlab.local:8081 (or the SECONDARY_HTTP_PORT you configured)
- SSH: ssh://gitlab.local:2223 (or the SECONDARY_SSH_PORT you configured)

Default username: `root`  
Default password: Check the initial root password in the logs:
```bash
docker exec -it gitlab-geo-primary grep 'Password:' /etc/gitlab/initial_root_password
```

## Hostnames Setup

For proper Geo operation, add these hostnames to your `/etc/hosts` file:

```bash
# Add to /etc/hosts
127.0.0.1 gitlab-primary.local
127.0.0.1 gitlab-secondary.local
```

## Testing Geo Replication

1. After deploying, login to the primary node and create a project with some content
2. Wait a few minutes for replication to occur (check the secondary node's status)
3. Access the secondary node to verify that the content has been replicated

To check replication status on the secondary node:

```bash
docker exec -it gitlab-geo-secondary gitlab-rake geo:status
```

## Customizing Geo Configuration

To customize the Geo configuration:

1. Edit the configuration files:
   - Primary node: `config/gitlab-primary.rb`
   - Secondary node: `config/gitlab-secondary.rb`

2. Apply changes by running:
   ```bash
   # For the primary node
   docker exec -it gitlab-geo-primary gitlab-ctl reconfigure
   
   # For the secondary node
   docker exec -it gitlab-geo-secondary gitlab-ctl reconfigure
   ```

## Troubleshooting

1. **Replication Issues**: Check the Geo log for errors:

```bash
docker exec -it gitlab-geo-secondary gitlab-rake geo:status
docker exec -it gitlab-geo-secondary gitlab-ctl tail geo-logcursor
```

2. **Database Connection Issues**: Verify the secondary can connect to the primary:

```bash
docker exec -it gitlab-geo-secondary gitlab-rake gitlab:doctor:geo
```

3. **OAuth Issues**: If authorization fails between primary and secondary, check:
   - The same secrets are configured on both nodes
   - Hostnames are correctly set in `/etc/hosts`

## Reference

- [GitLab Geo Documentation](https://docs.gitlab.com/ee/administration/geo/index.html)
- [Geo Data Types Replication](https://docs.gitlab.com/ee/administration/geo/replication/datatypes.html)