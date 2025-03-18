## Primary GitLab node configuration

# Basic GitLab URL and host settings
external_url 'http://geo-deployment-primary.local'
gitlab_rails['gitlab_host'] = 'geo-deployment-primary.local'
gitlab_rails['gitlab_port'] = 80
gitlab_rails['gitlab_https'] = false

# Configure as Geo primary
gitlab_rails['geo_node_name'] = 'geo-deployment-primary'
gitlab_rails['geo_primary_role'] = true

# PostgreSQL configuration
postgresql['enable'] = true
postgresql['listen_address'] = '*'
postgresql['port'] = 5432
postgresql['sql_user'] = 'gitlab'
postgresql['sql_password'] = 'gitlab'
postgresql['md5_auth_cidr_addresses'] = ['0.0.0.0/0']

# Enable tracking database
geo_postgresql['enable'] = true
geo_postgresql['listen_address'] = '*'

# Redis settings
redis['enable'] = true
redis['bind'] = '0.0.0.0'

# GitLab Shell SSH port
gitlab_rails['gitlab_shell_ssh_port'] = 2222

# Disable automatic migrations
gitlab_rails['auto_migrate'] = false

# Configure Prometheus monitoring
prometheus['enable'] = true
prometheus['listen_address'] = '0.0.0.0:9090'

# GitLab Geo-specific settings
gitlab_rails['geo_registry_replication_enabled'] = true
gitlab_rails['geo_status_enabled'] = true

# Configure SMTP for email
gitlab_rails['smtp_enable'] = false

# Git settings
git_data_dirs({
  'default' => { 'path' => '/var/opt/gitlab/git-data' }
})

# Set the shared path (used for both primary and secondary nodes)
gitlab_rails['shared_path'] = '/var/opt/gitlab/gitlab-rails/shared'

# Backup settings
gitlab_rails['backup_path'] = '/var/opt/gitlab/backups'