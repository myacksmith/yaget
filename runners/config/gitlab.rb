# GitLab configuration for CI/CD runners environment
# Standard configuration with CI/CD optimizations

## URL and SSH settings
external_url 'http://gitlab.local'
gitlab_rails['gitlab_shell_ssh_port'] = 2222

## Disable Let's Encrypt
letsencrypt['enable'] = false

## Resource optimization for development/testing
puma['worker_processes'] = 2
sidekiq['concurrency'] = 15  # Increased for better CI job processing
postgresql['shared_buffers'] = '512MB'
prometheus_monitoring['enable'] = false

## CI/CD settings
# Increase job timeout for testing purposes
gitlab_rails['gitlab_default_projects_features_builds'] = true
gitlab_rails['gitlab_ci_default_timeout'] = 3600  # 1 hour
gitlab_rails['ci_pipeline_schedule_worker_cron'] = "*/5 * * * *"
gitlab_rails['gitlab_ci_all_broken_builds_worker_cron'] = "*/5 * * * *"
gitlab_rails['gitlab_ci_pipeline_cache_expiry_worker_cron'] = "*/30 * * * *"

# Adjust Sidekiq queues for CI/CD
gitlab_rails['sidekiq_queues'] = [
  "default",
  "mailers",
  "pipeline",
  "pipeline_processing",
  "pipeline_default",
  "pipeline_cache",
  "pipeline_hooks"
]

# Redis settings (adjusted for CI/CD)
redis['maxmemory'] = '512mb'
redis['maxmemory_policy'] = 'allkeys-lru'

# Enable shared runners
gitlab_rails['gitlab_ci_shared_runners_enabled'] = true
gitlab_rails['gitlab_ci_shared_runners_text'] = 'Shared runners are available for all projects'

# Disable some features to save resources
pages_nginx['enable'] = false
gitlab_pages['enable'] = false
registry['enable'] = false
gitlab_kas['enable'] = false
sentinels['enable'] = false
grafana['enable'] = false