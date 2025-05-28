# Examples

## Basic GitLab

Minimal setup with one GitLab instance:

```
templates/basic/gitlab/
└── gitlab.rb              # GitLab configuration
```

Deploy:
```bash
./deploy.sh basic

[1/1] gitlab
  Environment:
    From ./.env:
      GITLAB_VERSION=latest
  
  Image: gitlab/gitlab-ee:latest
  Container: basic-gitlab
  ✓ Ports:
    80 → localhost:32768
    443 → localhost:32769
```

## GitLab with LDAP

Multi-service deployment:

```
templates/sso/
├── gitlab/
│   ├── .env               # LDAP connection settings
│   └── gitlab.rb.tpl      # Config template with ${LDAP_*} variables
└── ldap/
    ├── .env               # LDAP server settings
    ├── post-deploy.sh     # Load initial users
    └── ldif/
        └── users.ldif     # User definitions
```

Deploy:
```bash
./deploy.sh sso

[1/2] gitlab
  Environment:
    From ./templates/sso/gitlab/.env:
      EXTERNAL_URL=http://gitlab.local
      
    From ./.env:
      GITLAB_VERSION=16.7.0-ee.0
      LDAP_BIND_DN=cn=admin,dc=example,dc=org
      LDAP_BIND_PASSWORD=admin
  
  Container: sso-gitlab
  ✓ Ports:
    80 → localhost:32771

[2/2] ldap
  Environment:
    From ./templates/sso/ldap/.env:
      LDAP_VERSION=1.5.0
      LDAP_ORGANISATION=Example Inc
      LDAP_ADMIN_PASSWORD=admin
      
  Container: sso-ldap
  >>> Running post-deploy.sh
      LDAP users loaded
```

Services connect using `${DEPLOYMENT_NAME}-${SERVICE_NAME}` hostnames.

## Working with Running Deployments

### Test configuration changes
```bash
docker exec -it basic-gitlab vi /etc/gitlab/gitlab.rb
docker exec basic-gitlab gitlab-ctl reconfigure
```

### Save changes back to template
```bash
docker cp basic-gitlab:/etc/gitlab/gitlab.rb templates/basic/gitlab/gitlab.rb
```

### Access data directly
```bash
# Logs
tail -f artifacts/basic/gitlab/volumes/logs/gitlab-rails/production.log

# Backup
tar -czf backup.tar.gz artifacts/basic/
```

## Variable Precedence

Create `templates/custom/gitlab/.env`:
```bash
GITLAB_VERSION=16.0.0-ee.0
EXTERNAL_URL=https://gitlab.test
```

Override on command line:
```bash
# This wins
GITLAB_VERSION=15.11.0 ./deploy.sh custom

[1/1] gitlab
  Environment:
    From command line:
      GITLAB_VERSION=15.11.0
      
    From ./templates/custom/gitlab/.env:
      EXTERNAL_URL=https://gitlab.test
```

Command line always wins over .env files.
