# GitLab with Omnibus External Services

This template sets up a GitLab instance with external PostgreSQL and Redis services, but using the same GitLab Omnibus package for all components. This approach ensures you're using the exact same database and cache versions that GitLab is designed to work with.

## Features

- GitLab Enterprise Edition with external database configuration
- PostgreSQL server using Omnibus GitLab (same version as used internally)
- Redis server using Omnibus GitLab (same version as used internally)
- Separate container for each service
- Consistent versioning across all components

## Quick Deploy

From the main project directory:

```bash
./deploy.sh omnibus-db
```

Or with a specific version:

```bash
./deploy.sh omnibus-db --version 15.11.3-ee.0
```

## Configuration Options

Edit the `.env` file to customize the deployment:

| Variable | Description | Default |
|----------|-------------|---------|
| `DEPLOYMENT_NAME` | Name for the deployment | `gitlab-omnibus-db` |
| `GITLAB_IMAGE` | GitLab Docker image | `gitlab/gitlab-ee` |
| `GITLAB_VERSION` | GitLab version tag | `latest` |
| `POSTGRES_PASSWORD` | PostgreSQL password | `gitlab_postgres_password` |
| `POSTGRES_PORT` | PostgreSQL port mapping | `5432` |
| `REDIS_PASSWORD` | Redis password | `gitlab_redis_password` |
| `REDIS_PORT` | Redis port mapping | `6379` |
| `HTTP_PORT` | HTTP port mapping | `8080` |
| `HTTPS_PORT` | HTTPS port mapping | `8443` |
| `SSH_PORT` | SSH port mapping | `2222` |

## Architecture

The setup consists of three main components, all using the same GitLab Omnibus image:

1. **GitLab Server**: The main GitLab instance with bundled database services disabled
2. **PostgreSQL Server**: Omnibus container running only PostgreSQL
3. **Redis Server**: Omnibus container running only Redis

This approach ensures perfect compatibility while still testing external database configurations.

## Advantages Over Standard External DB Setup

1. **Version Consistency**: Uses the exact same PostgreSQL and Redis versions that GitLab is tested with
2. **Configuration Compatibility**: Uses the Omnibus configuration patterns GitLab engineers are familiar with
3. **Upgrade Testing**: Can test database upgrades as part of GitLab version upgrades
4. **Customer Simulation**: Many customers use this split architecture in production

## Accessing GitLab

- Web UI: http://localhost:8080 (or the port you configured)
- Default username: `root`
- Default password: Check the initial root password in the logs:

```bash
docker exec -it gitlab-omnibus-db-gitlab grep 'Password:' /etc/gitlab/initial_root_password
```

## Accessing Database Services

### PostgreSQL

Connect directly to the PostgreSQL database:

```bash
docker exec -it gitlab-omnibus-db-postgres gitlab-psql -d gitlabhq_production

# Or from your host machine
psql -h localhost -p 5432 -U gitlab -d gitlabhq_production
```

### Redis

Connect directly to the Redis server:

```bash
docker exec -it gitlab-omnibus-db-redis gitlab-redis-cli

# Or from your host machine
redis-cli -h localhost -p 6379 -a gitlab_redis_password
```

## Customizing Configuration

To customize the configuration:

1. Edit the service-specific configuration files:
   - GitLab: `config/gitlab.rb`
   - PostgreSQL: `config/postgres.rb`
   - Redis: `config/redis.rb`

2. Apply changes by running:
   ```bash
   # For the GitLab server
   docker exec -it gitlab-omnibus-db-gitlab gitlab-ctl reconfigure
   
   # For the PostgreSQL server
   docker exec -it gitlab-omnibus-db-postgres gitlab-ctl reconfigure
   
   # For the Redis server
   docker exec -it gitlab-omnibus-db-redis gitlab-ctl reconfigure
   ```

## Troubleshooting

1. **Database Connection Issues**:

```bash
# Check PostgreSQL connection
docker exec -it gitlab-omnibus-db-gitlab gitlab-rails runner "puts ActiveRecord::Base.connection.execute('SELECT 1').to_a"

# Check Redis connection
docker exec -it gitlab-omnibus-db-gitlab gitlab-rails runner "puts Gitlab::Redis::SharedState.with { |redis| redis.ping }"
```

2. **Service Status**:

```bash
# Check PostgreSQL status
docker exec -it gitlab-omnibus-db-postgres gitlab-ctl status postgresql

# Check Redis status
docker exec -it gitlab-omnibus-db-redis gitlab-ctl status redis
```

3. **Viewing Logs**:

```bash
# PostgreSQL logs
docker exec -it gitlab-omnibus-db-postgres gitlab-ctl tail postgresql

# Redis logs
docker exec -it gitlab-omnibus-db-redis gitlab-ctl tail redis
```

## Reference

- [GitLab High Availability Configuration](https://docs.gitlab.com/ee/administration/high_availability/)
- [GitLab Database Configuration](https://docs.gitlab.com/ee/administration/postgresql/external.html)
- [GitLab Redis Configuration](https://docs.gitlab.com/ee/administration/redis/external.html)