# PostgreSQL server configuration (Omnibus)
# This configures a standalone PostgreSQL server from GitLab Omnibus

## Define roles - PostgreSQL only
roles ['postgres']

## Disable all other services
nginx['enable'] = false
redis['enable'] = false
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

## Configure PostgreSQL
postgresql['enable'] = true
postgresql['listen_address'] = '0.0.0.0'
postgresql['port'] = 5432
postgresql['shared_buffers'] = '512MB'
postgresql['work_mem'] = '8MB'
postgresql['maintenance_work_mem'] = '64MB'
postgresql['max_connections'] = 100
postgresql['max_worker_processes'] = 4
postgresql['log_min_duration_statement'] = 1000
postgresql['hot_standby'] = 'off'
postgresql['random_page_cost'] = 2.0
postgresql['log_temp_files'] = -1
postgresql['log_checkpoints'] = 'on'
postgresql['password'] = 'gitlab_postgres_password'
postgresql['sql_user_password'] = 'gitlab_postgres_password'

## Authentication settings
postgresql['md5_auth_cidr_addresses'] = ['0.0.0.0/0']
postgresql['trust_auth_cidr_addresses'] = ['127.0.0.1/32']

## Configure logging
logging['logrotate_frequency'] = 'daily'
logging['logrotate_size'] = '10M'