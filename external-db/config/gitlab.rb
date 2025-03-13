# GitLab configuration with external PostgreSQL and Redis
# This configures GitLab to use external database services

## URL and SSH settings
external_url 'http://gitlab.local'
gitlab_rails['gitlab_shell_ssh_port'] = 2222

## Disable Let's Encrypt
letsencrypt['enable'] = false

## Resource optimization for development/testing
puma['worker_processes'] = 2
sidekiq['concurrency'] = 10
prometheus_monitoring['enable'] = false

## Disable bundled PostgreSQL and Redis
postgresql['enable'] = false
redis['enable'] = false

## Configure external PostgreSQL
gitlab_rails['db_adapter'] = "postgresql"
gitlab_rails['db_encoding'] = "unicode"
gitlab_rails['db_host'] = "postgres"
gitlab_rails['db_port'] = 5432
gitlab_rails['db_username'] = "gitlab"
gitlab_rails['db_password'] = "gitlab_password"
gitlab_rails['db_database'] = "gitlabhq_production"

## Configure external Redis
gitlab_rails['redis_host'] = "redis"
gitlab_rails['redis_port'] = 6379
gitlab_rails['redis_password'] = "redis_password"
gitlab_rails['redis_ssl'] = false

# Cache configuration
gitlab_rails['redis_cache_instance'] = "redis://redis:redis_password@redis:6379/0"
gitlab_rails['redis_queues_instance'] = "redis://redis:redis_password@redis:6379/1"
gitlab_rails['redis_shared_state_instance'] = "redis://redis:redis_password@redis:6379/2"
gitlab_rails['redis_actioncable_instance'] = "redis://redis:redis_password@redis:6379/3"

# Logging settings
logging['logrotate_frequency'] = 'daily'
logging['logrotate_size'] = '10M'

# Disable unnecessary services
pages_nginx['enable'] = false
gitlab_pages['enable'] = false
registry['enable'] = false
gitlab_kas['enable'] = false
sentinel['enable'] = false


# Database cleanup settings
gitlab_rails['db_statement_timeout'] = 15_000 # 15s
gitlab_rails['db_idle_timeout'] = 60 # 60s
