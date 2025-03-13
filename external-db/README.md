# GitLab with External Database

This template sets up a GitLab instance with external PostgreSQL and Redis services. This configuration is useful for testing database-related issues or simulating environments where GitLab uses external database services.

## Features

- GitLab Enterprise Edition with external database configuration
- Dedicated PostgreSQL database server
- Dedicated Redis server
- Separate container for each service
- Direct access to database for debugging

## Quick Deploy

From the main project directory:

```bash
./deploy.sh external-db
```

Or with a specific version:

```bash
./deploy.sh external-db --version 15.11.3-ee.0
```

## Configuration Options

Edit the `.env` file to customize the deployment:

| Variable | Description | Default |
|----------|-------------|---------|
| `DEPLOYMENT_NAME` | Name for the deployment | `gitlab-external-db` |
| `GITLAB_IMAGE` | GitLab Docker image | `gitlab/gitlab-ee` |
| `GITLAB_VERSION` | GitLab version tag | `latest` |
| `POSTGRES_IMAGE` | PostgreSQL Docker image | `postgres` |
| `POSTGRES_VERSION` | PostgreSQL version tag | `13` |
| `POSTGRES_PASSWORD` | PostgreSQL password | `gitlab_password` |
| `POSTGRES_PORT` | PostgreSQL port mapping | `5432` |
| `REDIS_IMAGE` | Redis Docker image | `redis` |
| `REDIS_VERSION` | Redis version tag | `6.2-alpine` |
| `REDIS_PASSWORD` | Redis password | `redis_password` |
| `REDIS_PORT` | Redis port mapping | `6379` |
| `HTTP_PORT` | HTTP port mapping | `8080` |
| `HTTPS_PORT` | HTTPS port mapping | `8443` |
| `SSH_PORT` | SSH port mapping | `2222` |

## Architecture

The setup consists of three main components:

1. **GitLab Server**: The main GitLab instance without bundled database services
2. **PostgreSQL Server**: External database for GitLab
3. **Redis Server**: External cache and queue service for GitLab

## Accessing GitLab

- Web UI: http://localhost:8080 (or the port you configured)
- Default username: `root`
- Default password: Check the initial root password in the logs:

```bash
docker exec -it gitlab-external-db-gitlab grep 'Password:' /etc/gitlab/initial_root_password
```

## Accessing Database Services

### PostgreSQL

Connect directly to the PostgreSQL database:

```bash
docker exec -it gitlab-external-db-postgres psql -U gitlab -d gitlabhq_production

# Or from your host machine
psql -h localhost -p 5432 -U gitlab -d gitlabhq_production
```

### Redis

Connect directly to the Redis server:

```bash
docker exec -it gitlab-external-db-redis redis-cli -a redis_password

# Or from your host machine
redis-cli -h localhost -p 6379 -a redis_password
```

## Customizing Database Configuration

To customize the database configuration:

1. Edit GitLab configuration in `config/gitlab.rb`
2. For PostgreSQL settings, modify the environment variables in the `docker-compose.yml` file
3. For Redis settings, modify the `command` parameter in the `docker-compose.yml` file
4. Apply changes by running:
   ```bash
   docker exec -it gitlab-external-db-gitlab gitlab-ctl reconfigure
   ```

## Database Maintenance

### PostgreSQL Backup and Restore

```bash
# Backup
docker exec -it gitlab-external-db-postgres pg_dump -U gitlab gitlabhq_production > gitlab_db_backup.sql

# Restore
cat gitlab_db_backup.sql | docker exec -i gitlab-external-db-postgres psql -U gitlab gitlabhq_production
```

### Redis Backup and Restore

```bash
# Backup
docker exec -it gitlab-external-db-redis redis-cli -a redis_password --rdb /data/redis_backup.rdb

# Restore (requires container restart)
docker cp redis_backup.rdb gitlab-external-db-redis:/data/dump.rdb
docker compose restart redis
```

## Troubleshooting

1. **Database Connection Issues**:

```bash
# Check PostgreSQL connection
docker exec -it gitlab-external-db-gitlab gitlab-rails runner "puts ActiveRecord::Base.connection.execute('SELECT 1').to_a"

# Check Redis connection
docker exec -it gitlab-external-db-gitlab gitlab-rails runner "puts Gitlab::Redis::SharedState.with { |redis| redis.ping }"
```

2. **Database Performance Issues**:

```bash
# Check PostgreSQL query performance
docker exec -it gitlab-external-db-postgres psql -U gitlab -d gitlabhq_production -c "SELECT * FROM pg_stat_activity WHERE state = 'active';"
```

3. **Service Health Checks**:

```bash
# Check PostgreSQL health
docker exec -it gitlab-external-db-postgres pg_isready -U gitlab

# Check Redis health
docker exec -it gitlab-external-db-redis redis-cli -a redis_password ping
```

## Reference

- [GitLab Database Configuration](https://docs.gitlab.com/ee/administration/postgresql/external.html)
- [GitLab Redis Configuration](https://docs.gitlab.com/ee/administration/redis/external.html)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Redis Documentation](https://redis.io/documentation)