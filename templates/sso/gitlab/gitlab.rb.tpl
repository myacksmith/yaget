external_url '${EXTERNAL_URL}'

# LDAP Configuration
gitlab_rails['ldap_enabled'] = true
gitlab_rails['ldap_servers'] = {
  'main' => {
    'label' => 'Company LDAP',
    'host' => '${DEPLOYMENT_NAME}-ldap',
    'port' => 389,
    'uid' => 'uid',
    'bind_dn' => '${LDAP_BIND_DN}',
    'password' => '${LDAP_BIND_PASSWORD}',
    'base' => '${LDAP_BASE}',
    'active_directory' => false
  }
}