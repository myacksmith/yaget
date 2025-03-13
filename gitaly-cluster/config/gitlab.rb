# Main GitLab configuration with Gitaly Cluster
# For GitLab server in a Gitaly Cluster setup

## External URL and SSH settings
external_url 'http://gitlab.local'
gitlab_rails['gitlab_shell_ssh_port'] = 2222

## Disable Let's Encrypt
letsencrypt['enable'] = false

## Resource optimization
puma['worker_processes'] = 2
sidekiq['concurrency'] = 10
postgresql['shared_buffers'] = '512MB'
prometheus_monitoring['enable'] = false

# Disable local Gitaly
gitaly['enable'] = false

# Configure Gitaly Cluster
git_data_dirs({
  'default' => { 'gitaly_address' => 'tcp://gitaly1.local:8075' },
  'storage1' => { 'gitaly_address' => 'tcp://gitaly1.local:8075' },
  'storage2' => { 'gitaly_address' => 'tcp://gitaly2.local:8075' },
})

gitlab_rails['gitaly_token'] = 'gitaly-token'

# Disable Praefect for this simple Gitaly Cluster example
praefect['enable'] = false

# Cache configuration (memory savings)
redis['maxmemory'] = '256mb'
redis['maxmemory_policy'] = 'allkeys-lru'

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