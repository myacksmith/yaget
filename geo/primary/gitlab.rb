# Primary Geo node configuration
external_url 'http://geo-primary.local'

# Enable Geo primary role
gitlab_rails['geo_node_name'] = 'geo-primary'
gitlab_rails['geo_primary_role'] = true
gitlab_rails['initial_license_file'] = './Gitlab.gitlab-license'

# Database settings
postgresql['enable'] = true
postgresql['listen_address'] = '*'
postgresql['port'] = 5432
postgresql['sql_user'] = 'gitlab'
postgresql['sql_password'] = 'gitlab'
postgresql['md5_auth_cidr_addresses'] = ['0.0.0.0/0']

# Redis settings
redis['enable'] = true
redis['bind'] = '0.0.0.0'

# Enable tracking database
geo_postgresql['enable'] = true
geo_postgresql['listen_address'] = '*'

# Set up SSH keys path
gitlab_rails['gitlab_ssh_host'] = 'geo-primary.local'

# Configure Postgres replication settings
postgresql['sql_replication_user'] = 'gitlab_replicator'
postgresql['sql_replication_password'] = 'gitlab_replication_password'
postgresql['wal_level'] = 'replica'
postgresql['max_wal_senders'] = 10
postgresql['max_replication_slots'] = 10
postgresql['wal_keep_segments'] = 10
