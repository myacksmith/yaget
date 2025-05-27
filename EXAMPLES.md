# Examples

## How Variables Work

Templates define required variables:
```ruby
# gitlab.rb.tpl
external_url '${EXTERNAL_URL}'
gitlab_rails['ldap_servers'] = {
  'main' => {
    'host' => '${DEPLOYMENT_NAME}-ldap',
    'bind_dn' => '${LDAP_BIND_DN}',
    'password' => '${LDAP_BIND_PASSWORD}'
  }
}
```

Provide values via `.env` or command line:
```bash
# .env
EXTERNAL_URL=http://gitlab.local
LDAP_BIND_DN=cn=admin,dc=example,dc=org
LDAP_BIND_PASSWORD=admin

# Or command line
EXTERNAL_URL=https://test.local ./deploy.sh sso
```

## Basic GitLab

Minimal setup with one GitLab instance:

```
templates/basic/gitlab/
└── gitlab.rb              # GitLab configuration
```

Deploy:
```bash
./deploy.sh basic
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

Services connect using `${DEPLOYMENT_NAME}-${SERVICE_NAME}` hostnames.

Deploy:
```bash
./deploy.sh sso

# Verify LDAP users
docker exec sso-ldap ldapsearch -x -b "dc=example,dc=org"

# Check GitLab LDAP
docker exec sso-gitlab gitlab-rake gitlab:ldap:check
```

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

# Repositories  
ls artifacts/basic/gitlab/volumes/data/git-data/repositories/

# Backup
tar -czf backup.tar.gz artifacts/basic/
```

## Custom Deployment Example

Create `templates/custom/`:

```yaml
# gitlab/docker-compose.yml.tpl
services:
  ${SERVICE_NAME}:
    image: "gitlab/gitlab-ee:${GITLAB_VERSION}"
    container_name: "${CONTAINER_NAME}"
    volumes:
      - "${CONFIG_PATH}/gitlab.rb:/etc/gitlab/gitlab.rb"
      - "${CONFIG_PATH}/license.txt:/etc/gitlab/license.txt"  # License file
      - "${SERVICE_DIR}/volumes/config:/etc/gitlab"
      - "${SERVICE_DIR}/volumes/data:/var/opt/gitlab"
    environment:
      - EXTERNAL_URL=${EXTERNAL_URL}
    networks:
      - "${NETWORK_NAME}"

# postgres/docker-compose.yml.tpl  
services:
  ${SERVICE_NAME}:
    image: "postgres:${POSTGRES_VERSION}"
    container_name: "${CONTAINER_NAME}"
    environment:
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - "${SERVICE_DIR}/volumes/data:/var/lib/postgresql/data"
    networks:
      - "${NETWORK_NAME}"
```

With `.env`:
```bash
# gitlab/.env
GITLAB_VERSION=latest
EXTERNAL_URL=https://gitlab.test

# postgres/.env
POSTGRES_VERSION=14
DB_PASSWORD=secure123
```

GitLab connects to PostgreSQL at `custom-postgres:5432`.