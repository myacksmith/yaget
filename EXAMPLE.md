# Example GitLab Test Deployments

This document provides examples of GitLab test environments you can create with YAGET (Yet Another GitLab Environment Tool).

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
│   └── gitlab.rb
│   └── .env  # Optional environment overrides
└── ldap/
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
      - LDAP_ADMIN_PASSWORD=${LDAP_PASSWORD:-admin}
    volumes:
      - "${SERVICE_DIR}/ldif:/bootstrap/ldif/custom"
    ports:
      - "${LDAP_PORT:-389}:389"
```

**gitlab/.env**:
```
# Override default variables
GITLAB_SMTP_ENABLED=true
```

## Port Allocation

Ports are assigned automatically:
- Base port uses a random range (10000-15000)
- Service index offsets prevent conflicts between services
- HTTP: base + service_index
- HTTPS: base + 100 + service_index
- SSH: base + 200 + service_index

## Destroying Environments

```bash
# Destroy and remove all data
./destroy.sh deployment-name

# Destroy but preserve data volumes
./destroy.sh deployment-name --keep-data
```