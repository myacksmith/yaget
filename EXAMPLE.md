# Example GitLab Test Deployments

## Basic Standalone GitLab

```
basic/
├── gitlab/
│   └── gitlab.rb
```

**gitlab.rb**:
```ruby
external_url 'http://basic-gitlab.local'
gitlab_rails['gitlab_shell_ssh_port'] = 2222
```

**Usage**:
```bash
./deploy.sh basic
# Or with specific version
./deploy.sh basic --version 15.11.3-ce.0
```

## LDAP Integration

```
sso/
├── gitlab/
│   └── .env  # Optional environment overrides
│   └── gitlab.rb
└── ldap/
│   └── .env
    ├── docker-compose.ldap.template  # Custom template
    └── post-deploy.sh  # Post-deployment automation
```

**ldap/docker-compose.ldap.template**:
```yaml
services:
  $SERVICE_NAME:
    image: "osixia/openldap:1.5.0"
    environment:
      - LDAP_DOMAIN=example.org
      - LDAP_ADMIN_PASSWORD=${LDAP_PASSWORD}
    volumes:
      - "${SERVICE_DIR}/ldif:/bootstrap/ldif/custom"
    ports:
      - "${LDAP_PORT}:389"
```

**gitlab/.env**:
```
# Override default variables
GITLAB_SMTP_ENABLED=true
```

**ldap/.env**:
```
LDAP_PASSWORD=password
```

## Destroying Environments

```bash
# Destroy and remove all data
./destroy.sh deployment-name

# Destroy but preserve data volumes
./destroy.sh deployment-name --keep-data
```
