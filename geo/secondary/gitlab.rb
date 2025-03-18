## Secondary GitLab node configuration

# Basic GitLab URL and host settings
external_url 'http://geo-deployment-secondary.local'
gitlab_rails['gitlab_host'] = 'geo-deployment-secondary.local'
gitlab_rails['gitlab_port'] = 80
gitlab_rails['gitlab_https'] = false

# Configure as Geo secondary
gitlab_rails['geo_node_name'] = 'geo-deployment-secondary'
gitlab_rails['geo_secondary_role'] = true

# Disable PostgreSQL as we'll connect to the primary's PostgreSQL
postgresql['enable'] = false

# PostgreSQL connection to primary
gitlab_rails['db_adapter'] = 'postgresql'
gitlab_rails['db_encoding'] = 'unicode'
gitlab_rails['db_host'] = 'geo-deployment-primary.local'
gitlab_rails['db_port'] = 5432
gitlab_rails['db_username'] = 'gitlab'
gitlab_rails['db_password'] = 'gitlab'
gitlab_rails['db_database'] = 'gitlabhq_production'

# Enable tracking database
geo_postgresql['enable'] = true
geo_postgresql['listen_address'] = '*'

# Redis connection to primary
gitlab_rails['redis_host'] = 'geo-deployment-primary.local'
gitlab_rails['redis_port'] = 6379

# GitLab Shell SSH port
gitlab_rails['gitlab_shell_ssh_port'] = 2223

# Disable automatic migrations
gitlab_rails['auto_migrate'] = false

# Configure Prometheus monitoring
prometheus['enable'] = true
prometheus['listen_address'] = '0.0.0.0:9090'

# Enable Geo Configuration
gitlab_rails['geo_node_name'] = 'geo-deployment-secondary'
gitlab_rails['geo_registry_replication_enabled'] = true
gitlab_rails['geo_status_enabled'] = true

# Configure SMTP for email
gitlab_rails['smtp_enable'] = false

# Set the shared path (used for both primary and secondary nodes)
gitlab_rails['shared_path'] = '/var/opt/gitlab/gitlab-rails/shared'

# Synchronization settings
geo_secondary['auto_migrate'] = true
geo_secondary['db_migrate'] = true

# Disable certain features on the secondary
gitlab_rails['geo_secondary_proxy_enabled'] = true