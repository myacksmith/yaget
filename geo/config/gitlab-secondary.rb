# GitLab Geo Secondary configuration
# This configures the secondary node in a Geo setup

## URL and SSH settings
external_url 'http://gitlab-secondary.local'
gitlab_rails['gitlab_ssh_host'] = 'gitlab-secondary.local'
gitlab_rails['gitlab_shell_ssh_port'] = 2223

## Disable Let's Encrypt
letsencrypt['enable'] = false

## Resource optimization for development/testing
puma['worker_processes'] = 2
sidekiq['concurrency'] = 10
postgresql['shared_buffers'] = '512MB'
prometheus_monitoring['enable'] = false

## Geo Secondary configuration
gitlab_rails['geo_secondary_role'] = true
gitlab_rails['geo_node_name'] = 'gitlab-secondary.local'

# Configure the same secret keys as on the primary
gitlab_rails['db_key_base'] = 'example-db-key-base-value'
gitlab_rails['secret_key_base'] = 'example-secret-key-base-value'
gitlab_rails['otp_key_base'] = 'example-otp-key-base-value'

# Configure secondary to connect to the primary's PostgreSQL database
gitlab_rails['db_host'] = 'gitlab-primary.local'
gitlab_rails['db_port'] = 5432
gitlab_rails['db_username'] = 'gitlab'
gitlab_rails['db_password'] = 'gitlab_sql_password'

# Configure secondary to connect to the primary's Redis
gitlab_rails['redis_host'] = 'gitlab-primary.local'
gitlab_rails['redis_port'] = 6379

# Configure secondary to connect to the tracking database
gitlab_rails['geo_postgresql'] = {
  'enable' => true,
  'host' => 'gitlab-primary.local',
  'port' => 5431,
  'db_username' => 'gitlab_geo',
  'db_password' => 'geo_postgresql_password'
}

# Generate the gitlab-secrets.json file with proper content
gitlab_rails['auto_migrate'] = false

# Disable various services that will not be needed on secondary
prometheus['enable'] = false
alertmanager['enable'] = false
gitlab_exporter['enable'] = false
grafana['enable'] = false
pages_nginx['enable'] = false
gitlab_pages['enable'] = false
registry['enable'] = false
gitlab_kas['enable'] = false
sentinels['enable'] = false

# Logging settings
logging['logrotate_frequency'] = 'daily'
logging['logrotate_size'] = '10M'