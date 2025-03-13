# Gitaly server 2 configuration
# This configures a Gitaly server for the cluster

# Disable all other GitLab services
roles ['gitaly']
postgresql['enable'] = false
redis['enable'] = false
nginx['enable'] = false
puma['enable'] = false
sidekiq['enable'] = false
gitlab_workhorse['enable'] = false
prometheus['enable'] = false
alertmanager['enable'] = false
gitlab_exporter['enable'] = false
gitlab_rails['rake_cache_clear'] = false
gitlab_rails['auto_migrate'] = false

pages_nginx['enable'] = false
gitlab_pages['enable'] = false
registry['enable'] = false
gitlab_kas['enable'] = false
sentinel['enable'] = false

# Enable and configure Gitaly
gitaly['enable'] = true
gitaly['listen_addr'] = '0.0.0.0:8075'
gitaly['auth_token'] = 'gitaly-token'
gitaly['ruby_num_workers'] = 2
gitaly['concurrency'] = [
  {
    'rpc' => "/gitaly.SmartHTTPService/PostReceivePack",
    'max_per_repo' => 20
  }, {
    'rpc' => "/gitaly.SSHService/SSHUploadPack",
    'max_per_repo' => 20
  }
]

# Configure storage paths
git_data_dirs({
  'storage2' => {
    'path' => '/var/opt/gitlab/git-data/repositories'
  }
})

# Logging settings
logging['logrotate_frequency'] = 'daily'
logging['logrotate_size'] = '10M'
gitaly['logging_level'] = 'info'
gitaly['logging_format'] = 'json'
gitaly['log_directory'] = '/var/log/gitlab/gitaly'