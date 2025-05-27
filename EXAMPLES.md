# Example GitLab Test Deployments

## Basic Standalone GitLab

The simplest deployment with just GitLab:

```
templates/
└── basic/
    └── gitlab/
        └── gitlab.rb      # GitLab configuration
```

**Usage**:
```bash
# Deploy with defaults
./deploy.sh basic

# Override version
GITLAB_VERSION=15.11.3-ce.0 ./deploy.sh basic

# Check initial root password
docker exec -it basic-gitlab grep 'Password: ' /etc/gitlab/initial_root_password
```

## GitLab with LDAP

Multi-service deployment with LDAP authentication:

```
templates/
└── sso/
    ├── gitlab/
    │   ├── gitlab.rb.tpl      # Templated config using ${LDAP_*} variables
    │   └── .env               # LDAP connection settings
    └── ldap/
        ├── docker-compose.yml.tpl  # Custom LDAP container template
        ├── .env                    # LDAP server configuration
        ├── post-deploy.sh          # Script to load initial users
        └── ldif/
            └── users.ldif          # Initial LDAP users
```

The GitLab service will connect to LDAP using hostname `${DEPLOYMENT_NAME}-ldap`.

**Usage**:
```bash
# Deploy the SSO environment
./deploy.sh sso

# Test LDAP connectivity
docker exec sso-ldap ldapsearch -x -b "dc=example,dc=org"

# Access GitLab and log in with LDAP users
```

## Working with Deployments

Once deployed, all files and data are in the artifacts directory:

```
artifacts/sso/
├── gitlab/
│   ├── docker-compose.yml     # Generated from template
│   ├── gitlab.rb             # Generated from gitlab.rb.tpl
│   └── volumes/              # All GitLab data (bind mounted)
│       ├── config/
│       ├── logs/
│       └── data/
└── ldap/
    ├── docker-compose.yml
    ├── ldif/                 # Copied from source
    │   └── users.ldif
    └── volumes/              # All LDAP data (bind mounted)
        ├── config/
        └── data/
```

### Modifying Configurations

```bash
# Edit generated config
vim artifacts/sso/gitlab/gitlab.rb

# Restart to apply changes
docker compose -f artifacts/sso/gitlab/docker-compose.yml restart

# View logs
tail -f artifacts/sso/gitlab/volumes/logs/gitlab-rails/production.log

# Reset to original
./deploy.sh sso  # Regenerates all files from templates
```

### Direct Access to Data

```bash
# Browse GitLab repositories
ls artifacts/sso/gitlab/volumes/data/git-data/repositories/

# Check LDAP database
ls artifacts/sso/ldap/volumes/data/

# Backup entire deployment
tar -czf sso-backup.tar.gz artifacts/sso/
```

## Cleanup

```bash
# Remove everything including data
./destroy.sh sso

# Keep artifacts for inspection
./destroy.sh sso --keep-data
```

## Advanced Example: GitLab with External PostgreSQL

```
templates/
└── gitlab-ext-db/
    ├── gitlab/
    │   ├── gitlab.rb.tpl      # Disables bundled PostgreSQL, uses external
    │   └── .env               # Database connection settings
    └── postgres/
        ├── docker-compose.yml.tpl  # PostgreSQL container
        ├── .env                    # Database configuration
        └── pre-deploy.sh          # Database initialization
```

This structure allows GitLab to use an external PostgreSQL service at `${DEPLOYMENT_NAME}-postgres`.

## Tips

1. **Service Discovery**: Services can reach each other using `${DEPLOYMENT_NAME}-${SERVICE_NAME}` as the hostname
2. **Template Variables**: Any `*.tpl` file gets processed with environment substitution
3. **Data Persistence**: All data is in `artifacts/deployment/service/volumes/`
4. **Environment Variables**: Set in `.env` files or pass on command line
5. **Scripts**: Use `pre-deploy.sh` for setup, `post-deploy.sh` for configuration after start

For template syntax and available variables, see [TEMPLATES.md](TEMPLATES.md).