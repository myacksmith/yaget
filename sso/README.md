# Setting Up SSO with GitLab and LDAP

This guide explains how to set up Single Sign-On (SSO) for GitLab using the LDAP integration.

## Overview

The SSO deployment creates two primary services:

1. **LDAP Server**: Provides user authentication and directory services
2. **GitLab Instance**: Configured to use LDAP for authentication

## Deployment Steps

### 1. Set Up Directory Structure

Create the necessary directories and files:

```bash
# Create base directories
mkdir -p gitlab-test-env/sso/gitlab
mkdir -p gitlab-test-env/sso/ldap/ldif

# Copy configuration files
cp gitlab.rb gitlab-test-env/sso/gitlab/
cp docker-compose.ldap.yml.template gitlab-test-env/sso/ldap/
cp users.ldif gitlab-test-env/sso/ldap/ldif/
```

### 2. Deploy the Environment

```bash
cd gitlab-test-env
./deploy.sh sso
```

### 3. Update Your Hosts File

Add these entries to your `/etc/hosts` file:

```
127.0.0.1    sso-gitlab.local
127.0.0.1    sso-ldap.local
```

### 4. Verify LDAP Configuration

Use the `ldapsearch` command to verify the LDAP server is running correctly:

```bash
# Get the exposed port for the LDAP service
docker port sso-ldap 389

# Run ldapsearch (replace PORT with the actual port number)
ldapsearch -x -H ldap://localhost:PORT -b "dc=example,dc=org" -D "cn=admin,dc=example,dc=org" -w admin
```

This should return all entries in your LDAP directory.

### 5. Test GitLab LDAP Authentication

1. Access GitLab at http://sso-gitlab.local (check port in deployment summary)
2. Login with LDAP credentials:
   - Username: Use one from your LDIF file (e.g., `john`)
   - Password: Password from your LDIF file (e.g., `password123`)

## Troubleshooting

### LDAP Connection Issues

If GitLab can't connect to LDAP:

1. **Check Container Communication**:
   ```bash
   docker exec -it sso-gitlab bash -c "ping sso-ldap.local"
   ```

2. **Verify LDAP Port**:
   ```bash
   docker exec -it sso-gitlab bash -c "nc -zv sso-ldap.local 389"
   ```

3. **Check LDAP Server Logs**:
   ```bash
   docker logs sso-ldap
   ```

### GitLab LDAP Configuration Issues

If LDAP is running but authentication fails:

1. **Check GitLab LDAP Configuration**:
   ```bash
   docker exec -it sso-gitlab gitlab-rake gitlab:ldap:check
   ```

2. **View GitLab Logs**:
   ```bash
   docker exec -it sso-gitlab tail -f /var/log/gitlab/gitlab-rails/production.log
   ```

## Custom User Management

To add or modify users:

1. Create or edit the LDIF file:
   ```
   gitlab-test-env/sso/ldap/ldif/users.ldif
   ```

2. Use the `ldapadd` or `ldapmodify` commands to update the LDAP directory:
   ```bash
   # Get the port number
   export LDAP_PORT=$(docker port sso-ldap 389 | cut -d ':' -f 2)
   
   # Add new entries
   ldapadd -x -H ldap://localhost:$LDAP_PORT -D "cn=admin,dc=example,dc=org" -w admin -f new_users.ldif
   ```

Alternatively, you can modify the LDIF file and redeploy the environment.

## Advanced Configuration

### Customizing GitLab LDAP Settings

To modify how GitLab interacts with LDAP, edit `gitlab.rb` and adjust these settings:

```ruby
gitlab_rails['ldap_servers'] = {
  'main' => {
    # Change authentication requirements
    'user_filter' => '(memberOf=cn=developers,ou=groups,dc=example,dc=org)',
    
    # Map additional attributes
    'attributes' => {
      'username' => ['uid'],
      'email' => ['mail'],
      'name' => 'cn',
      'first_name' => 'givenName',
      'last_name' => 'sn'
    }
  }
}
```

After making changes, reconfigure GitLab:

```bash
docker exec -it sso-gitlab gitlab-ctl reconfigure
```

### Adding SSL/TLS

For a more secure setup, modify both the LDAP and GitLab configurations to use TLS encryption.