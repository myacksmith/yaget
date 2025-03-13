# GitLab Geo Primary configuration
# This configures the primary node in a Geo setup

## URL and SSH settings
external_url 'http://gitlab-primary.local'
gitlab_rails['gitlab_ssh_host'] = 'gitlab-primary.local'
gitlab_rails['gitlab_shell_ssh_port'] = 2222

## Disable Let's Encrypt
letsencrypt['enable'] = false

## Resource optimization for development/testing
puma['worker_processes'] = 2
sidekiq['concurrency'] = 10
postgresql['shared_buffers'] = '512MB'
prometheus_monitoring['enable'] = false

## PostgreSQL settings
postgresql['md5_auth_cidr_addresses'] = ['0.0.0.0/0']
postgresql['trust_auth_cidr_addresses'] = ['0.0.0.0/0']
postgresql['sql_user_password'] = 'gitlab_sql_password'

## Redis settings
redis['maxmemory'] = '256mb'
redis['maxmemory_policy'] = 'allkeys-lru'

## Geo Primary configuration
gitlab_rails['geo_primary_role'] = true
gitlab_rails['geo_node_name'] = 'gitlab-primary.local'

# Configure the secret keys (use the same values in primary and secondary)
gitlab_rails['db_key_base'] = 'example-db-key-base-value'
gitlab_rails['secret_key_base'] = 'example-secret-key-base-value'
gitlab_rails['otp_key_base'] = 'example-otp-key-base-value'

# Enable the Geo tracking database
geo_postgresql['enable'] = true
geo_postgresql['listen_address'] = '*'
geo_postgresql['md5_auth_cidr_addresses'] = ['0.0.0.0/0']
geo_postgresql['trust_auth_cidr_addresses'] = ['0.0.0.0/0']
geo_postgresql['sql_user_password'] = 'geo_postgresql_password'

# Configure the connection parameters for the secondary
postgresql['geo_secondary_program'] = '/opt/gitlab/embedded/bin/pg_basebackup'
postgresql['geo_secondary_options'] = '-R -X stream -c fast -P -v -h gitlab-primary.local -p 5432 -U gitlab_geo'

# Logging settings
logging['logrotate_frequency'] = 'daily'
logging['logrotate_size'] = '10M'

# Disable unnecessary services
pages_nginx['enable'] = false
gitlab_pages['enable'] = false
registry['enable'] = false
gitlab_kas['enable'] = false
sentinels['enable'] = false
grafana['enable'] = false