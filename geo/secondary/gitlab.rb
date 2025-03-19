# Secondary Geo node configuration
external_url 'http://geo-secondary.local'

# Configure as secondary node
gitlab_rails['geo_node_name'] = 'geo-secondary'
gitlab_rails['gitlab_shell_ssh_port'] = 2223
gitlab_rails['geo_secondary_role'] = true

# Database connection to primary
gitlab_rails['db_host'] = 'geo-primary'
gitlab_rails['db_port'] = 5432
gitlab_rails['db_username'] = 'gitlab'
gitlab_rails['db_password'] = 'gitlab'
gitlab_rails['db_adapter'] = 'postgresql'
gitlab_rails['db_encoding'] = 'unicode'

# Redis connection to primary
gitlab_rails['redis_host'] = 'geo-primary'

# Tracking database settings
geo_postgresql['enable'] = true
geo_postgresql['listen_address'] = '*'

# Set up SSH keys path
gitlab_rails['gitlab_ssh_host'] = 'geo-secondary.local'

# Disable local services that are on the primary
postgresql['enable'] = false
redis['enable'] = false

# Configure Gitaly connection to the primary
gitlab_rails['gitaly_token'] = 'gitaly_token_for_replication'
gitaly['configuration'] = {
  ruby_max_rss: 300000,
  concurrency: [
    {
      'rpc' => "/gitaly.SmartHTTPService/PostReceivePack",
      'max_per_repo' => 20
    }, {
      'rpc' => "/gitaly.SSHService/SSHUploadPack",
      'max_per_repo' => 20
    }
  ]
}