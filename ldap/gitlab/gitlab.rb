# GitLab configuration with LDAP authentication
# This configures GitLab to use LDAP for user authentication

## URL and SSH settings
external_url 'http://gitlab.local'
gitlab_rails['gitlab_shell_ssh_port'] = 2222

## Disable Let's Encrypt
letsencrypt['enable'] = false

## Resource optimization for development/testing
puma['worker_processes'] = 2
sidekiq['concurrency'] = 10
postgresql['shared_buffers'] = '512MB'
prometheus_monitoring['enable'] = false

## LDAP configuration
gitlab_rails['ldap_enabled'] = true
gitlab_rails['ldap_servers'] = {
  'main' => {
    'label' => 'LDAP',
    'host' =>  'ldap',
    'port' => 389,
    'uid' => 'uid',
    'encryption' => 'plain',
    'verify_certificates' => false,
    'bind_dn' => 'cn=admin,dc=example,dc=org',
    'password' => 'admin',
    'active_directory' => false,
    'base' => 'dc=example,dc=org',
    'user_filter' => '',
    'attributes' => {
      'username' => ['uid'],
      'email' => ['mail'],
      'name' => 'cn',
      'first_name' => 'givenName',
      'last_name' => 'sn'
    },
    'lowercase_usernames' => false
  }
}

# LDAP group sync settings
gitlab_rails['ldap_sync_worker_cron'] = "0 */1 * * *"
gitlab_rails['ldap_group_sync_worker_cron'] = "0 */1 * * *"

# Map LDAP groups to GitLab roles
gitlab_rails['ldap_servers']['main']['group_base'] = 'ou=groups,dc=example,dc=org'
gitlab_rails['ldap_servers']['main']['admin_group'] = 'administrators'
gitlab_rails['ldap_servers']['main']['external_groups'] = []
gitlab_rails['ldap_servers']['main']['sync_ssh_keys'] = false

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
sentinel['enable'] = false
