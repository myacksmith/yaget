# Redis server configuration (Omnibus)
# This configures a standalone Redis server from GitLab Omnibus

## Define roles - Redis only
roles ['redis']

## Disable all other services
nginx['enable'] = false
postgresql['enable'] = false
puma['enable'] = false
sidekiq['enable'] = false
gitlab_workhorse['enable'] = false
gitaly['enable'] = false
gitlab_rails['enable'] = false
prometheus['enable'] = false
alertmanager['enable'] = false
gitlab_exporter['enable'] = false
registry['enable'] = false
grafana['enable'] = false
pages_nginx['enable'] = false
gitlab_pages['enable'] = false
gitlab_kas['enable'] = false
sentinels['enable'] = false
consul['enable'] = false
unicorn['enable'] = false
gitaly['enable'] = false
mattermost['enable'] = false
mattermost_nginx['enable'] = false
monitoring_role['enable'] = false

## Configure Redis
redis['enable'] = true
redis['bind'] = '0.0.0.0'
redis['port'] = 6379
redis['password'] = 'gitlab_redis_password'
redis['maxmemory'] = '512mb'
redis['maxmemory_policy'] = 'allkeys-lru'
redis['tcp_timeout'] = 60
redis['tcp_keepalive'] = 300
redis['databases'] = 16

## Configure logging
logging['logrotate_frequency'] = 'daily'
logging['logrotate_size'] = '10M'