# GitLab with Gitaly Cluster

This template sets up a GitLab instance with a Gitaly cluster configuration, providing a distributed repository storage system. The setup includes a main GitLab instance and two Gitaly servers.

## Features

- GitLab Enterprise Edition with Gitaly cluster configuration
- Two dedicated Gitaly servers with separate storage
- Authentication between GitLab and Gitaly servers
- Multiple storage shards configuration

## Quick Deploy

From the main project directory:

```bash
./deploy.sh gitaly-cluster
```

Or with a specific version:

```bash
./deploy.sh gitaly-cluster --version 15.11.3-ee.0
```

## Configuration Options

Edit the `.env` file to customize the deployment:

| Variable | Description | Default |
|----------|-------------|---------|
| `DEPLOYMENT_NAME` | Name for the deployment | `gitlab-gitaly` |
| `GITLAB_IMAGE` | GitLab Docker image | `gitlab/gitlab-ee` |
| `GITLAB_VERSION` | GitLab version tag | `latest` |
| `HTTP_PORT` | HTTP port mapping | `8080` |
| `HTTPS_PORT` | HTTPS port mapping | `8443` |
| `SSH_PORT` | SSH port mapping | `2222` |

## Architecture

The setup consists of three main components:

1. **Main GitLab Server**: Runs all GitLab components except Gitaly
2. **Gitaly Server 1**: Dedicated to storage1 shard
3. **Gitaly Server 2**: Dedicated to storage2 shard

All services communicate over a dedicated network with authentication.

## Accessing GitLab

- Web UI: http://gitlab.local:8080 (or the port you configured)
- Default username: `root`
- Default password: Check the initial root password in the logs:

```bash
docker exec -it gitlab-gitaly-gitlab grep 'Password:' /etc/gitlab/initial_root_password
```

## Testing Gitaly Cluster

1. After deploying, create a project on GitLab
2. The project will be stored on one of the Gitaly servers based on the internal hashing algorithm
3. You can create multiple projects to see how they are distributed across the storage shards

To verify where a project is stored:

```bash
# Get the project ID (from the GitLab UI)
PROJECT_ID=1

# Check where it's stored
docker exec -it gitlab-gitaly-gitlab gitlab-rails runner "puts Project.find_by_id($PROJECT_ID).repository_storage"
```

## Customizing Gitaly Configuration

To customize the Gitaly configuration:

1. Edit the configuration files:
   - Main GitLab: `config/gitlab.rb`
   - Gitaly Server 1: `config/gitaly1.rb`
   - Gitaly Server 2: `config/gitaly2.rb`

2. Apply changes by running:
   ```bash
   # For the main GitLab server
   docker exec -it gitlab-gitaly-gitlab gitlab-ctl reconfigure
   
   # For Gitaly servers
   docker exec -it gitlab-gitaly-gitaly1 gitlab-ctl reconfigure
   docker exec -it gitlab-gitaly-gitaly2 gitlab-ctl reconfigure
   ```

## Troubleshooting

1. **Gitaly Connection Issues**: Check the logs for connection problems:

```bash
docker exec -it gitlab-gitaly-gitlab gitlab-rails runner "puts Gitlab::GitalyClient.connection_data"
```

2. **Repository Access Issues**: Verify Gitaly token configuration matches across all servers

3. **Performance Issues**: Check Gitaly server resource usage:

```bash
docker stats gitlab-gitaly-gitaly1 gitlab-gitaly-gitaly2
```

## Reference

- [GitLab Gitaly Cluster Documentation](https://docs.gitlab.com/ee/administration/gitaly/index.html)
- [Gitaly Repository Storage](https://docs.gitlab.com/ee/administration/repository_storage_paths.html)