# Base GitLab EE Setup

This directory contains a Docker Compose configuration for a standard GitLab Enterprise Edition instance. It's the foundation for other setups and can be used on its own for basic testing.

## Features

- GitLab Enterprise Edition with default settings
- Performance optimized for development/testing environments
- Configurable ports and versions
- Persistent storage volumes

## Quick Deploy

From the main project directory:

```bash
./deploy.sh base
```

Or with a specific version:

```bash
./deploy.sh base --version 15.11.3-ee.0
```

## Configuration Options

Edit the `.env` file to customize the deployment:

| Variable | Description | Default |
|----------|-------------|---------|
| `DEPLOYMENT_NAME` | Name for the deployment | `gitlab-base` |
| `GITLAB_IMAGE` | GitLab Docker image | `gitlab/gitlab-ee` |
| `GITLAB_VERSION` | GitLab version tag | `latest` |
| `HTTP_PORT` | HTTP port mapping | `8080` |
| `HTTPS_PORT` | HTTPS port mapping | `8443` |
| `SSH_PORT` | SSH port mapping | `2222` |

## Accessing GitLab

- Web UI: http://localhost:8080 (or the port you configured)
- Default username: `root`
- Default password: Check the initial root password in the logs:

```bash
docker exec -it gitlab-base-gitlab grep 'Password:' /etc/gitlab/initial_root_password
```

## Customizing GitLab Configuration

To customize the GitLab configuration:

1. Edit the `config/gitlab.rb` file
2. Apply changes by running:
   ```bash
   docker exec -it gitlab-base-gitlab gitlab-ctl reconfigure
   ```

## Troubleshooting

1. **Startup Issues**: GitLab may take several minutes to start. Check the logs:

```bash
docker compose logs -f gitlab
```

2. **Port Conflicts**: If ports are already in use, edit the `.env` file to change the port mappings.

3. **Reset Installation**: To completely reset the installation:

```bash
docker compose down -v
docker compose up -d
```

4. **Configuration Errors**: If GitLab fails to start after configuration changes, check the logs:

```bash
docker compose logs gitlab | grep "Config"
```

5. **URL Issues**: If you experience URL-related problems, make sure you've added the hostname to your `/etc/hosts` file:

```bash
# Add to /etc/hosts
127.0.0.1 gitlab.local
```

## Reference

- [GitLab Documentation](https://docs.gitlab.com/ee/)
- [GitLab Omnibus Configuration Options](https://docs.gitlab.com/omnibus/settings/configuration.html)