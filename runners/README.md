# GitLab with CI/CD Runners

This template sets up a GitLab instance with dedicated CI/CD runners to test pipeline functionality. The environment includes both shell and Docker executor runners.

## Features

- GitLab Enterprise Edition optimized for CI/CD workloads
- Shell runner for simple CI jobs
- Docker runner for containerized builds
- Automatic registration of runners
- CI/CD-optimized configuration

## Quick Deploy

From the main project directory:

```bash
./deploy.sh runners
```

Or with a specific version:

```bash
./deploy.sh runners --version 15.11.3-ee.0
```

## Configuration Options

Edit the `.env` file to customize the deployment:

| Variable | Description | Default |
|----------|-------------|---------|
| `DEPLOYMENT_NAME` | Name for the deployment | `gitlab-runners` |
| `GITLAB_IMAGE` | GitLab Docker image | `gitlab/gitlab-ee` |
| `GITLAB_VERSION` | GitLab version tag | `latest` |
| `RUNNER_IMAGE` | GitLab Runner image | `gitlab/gitlab-runner` |
| `RUNNER_VERSION` | GitLab Runner version | `latest` |
| `HTTP_PORT` | HTTP port mapping | `8080` |
| `HTTPS_PORT` | HTTPS port mapping | `8443` |
| `SSH_PORT` | SSH port mapping | `2222` |

## Architecture

The setup consists of three main components:

1. **GitLab Server**: The main GitLab instance
2. **Shell Runner**: For running shell scripts and commands
3. **Docker Runner**: For running containerized CI jobs

The Docker runner has access to the host's Docker daemon, allowing it to spawn sibling containers for builds.

## Accessing GitLab

- Web UI: http://gitlab.local:8080 (or the port you configured)
- Default username: `root`
- Default password: Check the initial root password in the logs:

```bash
docker exec -it gitlab-runners-gitlab grep 'Password:' /etc/gitlab/initial_root_password
```

## Testing CI/CD Pipelines

1. After deploying, login to GitLab and create a new project
2. Add a `.gitlab-ci.yml` file to your project with a simple pipeline configuration:

```yaml
stages:
  - test
  - build

test_job:
  stage: test
  script:
    - echo "Running tests"
  tags:
    - shell

build_job:
  stage: build
  image: alpine:latest
  script:
    - echo "Building application"
  tags:
    - docker
```

3. Commit the file to trigger a pipeline
4. Go to your project's CI/CD > Pipelines to see the pipeline execution

## Runner Information

The deployment includes two pre-configured runners:

### Shell Runner
- Name: `shell-runner`
- Executor: `shell`
- Tags: `shell`
- Concurrent jobs: 2

### Docker Runner
- Name: `docker-runner`
- Executor: `docker`
- Default image: `alpine:latest`
- Tags: `docker`
- Concurrent jobs: 3
- Privileged mode: enabled

## Customizing Runner Configuration

To customize the runner configuration:

1. Edit the runner config files:
   - Shell Runner: `config/runner-shell-config.toml`
   - Docker Runner: `config/runner-docker-config.toml`

2. Apply changes by restarting the runners:
   ```bash
   docker compose restart runner-shell
   docker compose restart runner-docker
   ```

## Troubleshooting

1. **Runner Registration Issues**: If runners don't register automatically:

```bash
# Get the registration token
docker exec -it gitlab-runners-gitlab gitlab-rails runner "puts Gitlab::CurrentSettings.current_application_settings.runners_registration_token"

# Register the shell runner manually
docker exec -it gitlab-runners-shell gitlab-runner register

# Register the docker runner manually
docker exec -it gitlab-runners-docker gitlab-runner register
```

2. **Job Execution Issues**: Check runner logs:

```bash
docker compose logs -f runner-shell
docker compose logs -f runner-docker
```

3. **Docker-in-Docker Issues**: For Docker executor problems, verify that the runner has access to the Docker socket and privileged mode is enabled

## Reference

- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/index.html)
- [GitLab Runner Documentation](https://docs.gitlab.com/runner/)
- [Pipeline Configuration Reference](https://docs.gitlab.com/ee/ci/yaml/index.html)