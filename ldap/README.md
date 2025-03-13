# GitLab with LDAP Authentication

This template sets up a GitLab instance integrated with OpenLDAP for authentication and user management. It includes a phpLDAPadmin interface for managing the LDAP directory.

## Features

- GitLab Enterprise Edition with LDAP authentication
- OpenLDAP server pre-configured with sample users and groups
- phpLDAPadmin for easy LDAP directory management
- Automatic group synchronization
- Administrative access mapping

## Quick Deploy

From the main project directory:

```bash
./deploy.sh ldap
```

Or with a specific version:

```bash
./deploy.sh ldap --version 15.11.3-ee.0
```

## Configuration Options

Edit the `.env` file to customize the deployment:

| Variable | Description | Default |
|----------|-------------|---------|
| `DEPLOYMENT_NAME` | Name for the deployment | `gitlab-ldap` |
| `GITLAB_VERSION` | GitLab version tag | `latest` |
| `HTTP_PORT` | HTTP port mapping | `8080` |
| `HTTPS_PORT` | HTTPS port mapping | `8443` |
| `SSH_PORT` | SSH port mapping | `2222` |
| `LDAP_ADMIN_PASSWORD` | LDAP admin password | `admin` |
| `LDAP_PORT` | LDAP port mapping | `3389` |
| `LDAPADMIN_PORT` | phpLDAPadmin port mapping | `8081` |

## Included LDAP Users

The template includes pre-configured LDAP users that you can use to test GitLab's LDAP integration:

| Username | Password | Email | Groups |
|----------|----------|-------|--------|
| john | password | john.doe@example.org | developers |
| jane | password | jane.smith@example.org | developers |
| admin | password | admin@example.org | administrators |

The `admin` user is automatically mapped to GitLab admin privileges through the `administrators` group.

## Accessing Services

- GitLab: http://localhost:8080 (or the port you configured)
- phpLDAPadmin: http://localhost:8081 (or the port you configured)
  - Login DN: `cn=admin,dc=example,dc=org`
  - Password: `admin` (or the password you configured)

## Testing LDAP Authentication

1. After deploying, wait for GitLab to fully initialize
2. Access GitLab at http://localhost:8080
3. Login with one of the LDAP users:
   - Username: `john`
   - Password: `password`

## Customizing LDAP Configuration

To customize the LDAP configuration:

1. Edit the `config/gitlab.rb` file to modify GitLab's LDAP settings
2. For the LDAP directory structure, edit `ldap/ldif/users.ldif`
3. Apply changes by running:
   ```bash
   docker exec -it gitlab-ldap-gitlab gitlab-ctl reconfigure
   ```

## Troubleshooting

- **LDAP Connection Issues**: Run `docker exec -it gitlab-ldap-gitlab gitlab-rake gitlab:ldap:check` to verify LDAP connectivity
- **User Synchronization**: If users aren't showing up, make sure they have valid email addresses in LDAP
- **Group Mapping**: Check group names match exactly between GitLab config and LDAP

## Reference

- [GitLab LDAP Documentation](https://docs.gitlab.com/ee/administration/auth/ldap/index.html)
- [OpenLDAP Documentation](https://www.openldap.org/doc/)