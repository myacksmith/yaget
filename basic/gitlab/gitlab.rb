# GitLab configuration for base environment
# Standard configuration with resource optimizations

## URL and SSH settings
external_url 'http://gitlab.local'
gitlab_rails['gitlab_shell_ssh_port'] = 2222

## Disable Let's Encrypt
letsencrypt['enable'] = false

## Resource optimization for development/testing
# Puma (Rails server)
puma['worker_processes'] = 2
puma['min_threads'] = 1
puma['max_threads'] = 4

# Sidekiq (background jobs)
sidekiq['concurrency'] = 10
sidekiq['min_concurrency'] = 5

# PostgreSQL
postgresql['shared_buffers'] = '512MB'
postgresql['max_worker_processes'] = 4

# Monitoring
prometheus_monitoring['enable'] = false

## Performance tweaks
gitlab_rails['env'] = {
  'MALLOC_CONF' => 'dirty_decay_ms:1000,muzzy_decay_ms:1000'
}

# Disable some features for test environments
gitlab_rails['gitlab_default_projects_features_container_registry'] = false
gitlab_pages['enable'] = false
registry['enable'] = false
gitlab_kas['enable'] = false
sentinel['enable'] = false

# Cache configuration (memory savings)
redis['maxmemory'] = '256mb'
redis['maxmemory_policy'] = 'allkeys-lru'

# Logging settings
logging['logrotate_frequency'] = 'daily'
logging['logrotate_size'] = '10M'
logging['logrotate_maxsize'] = '100M'

# Set time zone to UTC for consistency
gitlab_rails['time_zone'] = 'UTC'
