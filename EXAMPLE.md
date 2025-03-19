# Example GitLab Test Deployments

This document provides examples of various GitLab test environments you can create using this system.

## Basic Standalone GitLab

A simple standalone GitLab instance for basic testing:

```
basic/
├── gitlab/
│   └── gitlab.rb
└── README.md
```

### Configuration

**gitlab.rb**:
```ruby
external_url 'http://basic-gitlab.local'
gitlab_rails['gitlab_shell_ssh_port'] = 2222
```

### Usage

```bash
./deploy.sh basic
```

## LDAP/SSO Integration

GitLab with LDAP authentication for SSO testing:

```
sso/
├── gitlab/
│   └── gitlab.rb
└── ldap/
    ├── docker-compose.ldap.yml.template
    ├── ldif/
    │   └── users.ldif
    └── post-deploy.sh
```

### Configuration

**gitlab/gitlab.rb**:
```ruby
external_url 'http://sso-gitlab.local'
gitlab_rails['ldap_enabled'] = true
gitlab_rails['ldap_servers'] = {
  'main' => {
    'label' => 'LDAP',
    'host' => 'sso-ldap.local',
    'port' => 389,
    'bind_dn' => 'cn=admin,dc=example,dc=org',
    'password' => 'admin',
    'base' => 'dc=example,dc=org',
    'user_filter' => ''
  }
}
```

**ldap/ldif/users.ldif**:
```ldif
# Base domain
dn: dc=example,dc=org
objectClass: dcObject
objectClass: organization
o: Example Organization
dc: example

# Users
dn: uid=john,ou=users,dc=example,dc=org
objectClass: inetOrgPerson
uid: john
...
```

**ldap/post-deploy.sh**:
```bash
#!/bin/bash
# Wait for LDAP to be ready
sleep 5
# Add user entries
docker exec sso-ldap ldapadd -c -x -H ldap://localhost:389 \
  -D "cn=admin,dc=example,dc=org" -w admin \
  -f /container/service/slapd/assets/config/bootstrap/ldif/custom/users.ldif
```

### Usage

```bash
./deploy.sh sso
```

## Customizing Examples

All examples can be modified by:

1. Creating custom templates in `your-deployment/service-name/docker-compose.service-name.yml.template`
2. Writing post-deployment scripts in `your-deployment/service-name/post-deploy.sh`
3. Adjusting GitLab configurations in `your-deployment/service-name/gitlab.rb`

Port allocation is automatic and will be displayed in the deployment summary.