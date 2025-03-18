## GitLab configuration with LDAP integration

# Basic GitLab URL and host settings
external_url 'http://ldap-gitlab.local'
# LDAP server configuration
gitlab_rails['ldap_enabled'] = true
gitlab_rails['prevent_ldap_sign_in'] = false

###! Remember to change the 'main' key to a name for your LDAP server
###! **For example**:
###! gitlab_rails['ldap_servers'] = {
###!   'main' => {
###!     ...
###!   },
###!   'secondary' => {
###!     ...
###!   }
###! }

gitlab_rails['ldap_servers'] = {
  'main' => {
    'label' => 'LDAP',
    'host' =>  'ldap-ldap.local',
    'port' => 389,
    'uid' => 'uid',
    'bind_dn' => 'cn=admin,dc=example,dc=org',
    'password' => 'admin',
    'encryption' => 'plain', # "start_tls" or "simple_tls" or "plain"
    'verify_certificates' => false,
    'active_directory' => false,
    'allow_username_or_email_login' => true,
    'lowercase_usernames' => false,
    'block_auto_created_users' => false,
    'base' => 'dc=example,dc=org',
    'user_filter' => '',
    'attributes' => {
      'username' => ['uid'],
      'email' => ['mail'],
      'name' => 'cn',
      'first_name' => 'givenName',
      'last_name' => 'sn'
    },
    'group_base' => 'ou=groups,dc=example,dc=org',
    'admin_group' => 'gitlab-admins',
    ## EE Only
    # 'sync_ssh_keys' => 'sshPublicKey',
  }
}

# Enable LDAP Admin Sync
# gitlab_rails['ldap_admin_sync_enabled'] = true

# Configure SMTP for email
gitlab_rails['smtp_enable'] = false
