# Single Sign-On (SSO) Deployment

This deployment provides a GitLab instance with LDAP-based Single Sign-On (SSO).

## Configuration Overview

This deployment contains:

1. **GitLab Service**: Configured to authenticate against LDAP
2. **LDAP Service**: OpenLDAP server with predefined users and groups

## Directory Structure

```
sso/
├── gitlab/
│   └── gitlab.rb                # GitLab configuration with LDAP settings
└── ldap/
    ├── docker-compose.ldap.yml.template  # LDAP service template
    ├── ldif/                    # LDIF files directory
    │   └── users.ldif           # User definitions for LDAP
    └── post-deploy.sh           # Post-deployment script for LDAP
```

## Users and Groups

The default LDIF file includes these users:

| Username | Password    | Role     | Email                  |
|----------|-------------|----------|------------------------|
| john     | password123 | Admin    | john.doe@example.org   |
| jane     | password123 | Developer| jane.smith@example.org |
| bob      | password123 | Developer| bob.johnson@example.org|

## Deployment Instructions

1. Make sure the required files exist:
   ```bash
   # Check if files exist
   ls -la sso/gitlab/gitlab.rb
   ls -la sso/ldap/ldif/users.ldif
   ```

2. Deploy:
   ```bash
   ./deploy.sh sso
   ```

## Post-Deployment Setup

The deployment includes a post-deployment script (`post-deploy.sh`) that automatically:
1. Waits for the LDAP service to start
2. Adds the users and groups defined in users.ldif to the LDAP directory

The script runs automatically after deployment and requires no manual intervention.

## Verification

To verify everything is working correctly:

1. **Test LDAP Server**:
   ```bash
   # Check LDAP users
   docker exec sso-ldap ldapsearch -x -H ldap://localhost:389 \
     -D "cn=admin,dc=example,dc=org" -w admin \
     -b "dc=example,dc=org" "(objectClass=inetOrgPerson)"
   ```

2. **Test GitLab Login**:
   - Access GitLab at http://sso-gitlab.local (use the port shown in deployment summary)
   - Log in with LDAP credentials (e.g., username: john, password: password123)

## Troubleshooting

If you encounter issues:

1. **LDAP Connection Issues**:
   ```bash
   # Check if LDAP users were loaded properly
   docker exec sso-ldap ldapsearch -x -H ldap://localhost:389 \
     -D "cn=admin,dc=example,dc=org" -w admin \
     -b "dc=example,dc=org" "(uid=john)"
   
   # Manually run the post-deployment script
   ./sso/ldap/post-deploy.sh
   ```

2. **GitLab LDAP Configuration**:
   ```bash
   # Verify GitLab LDAP configuration
   docker exec sso-gitlab gitlab-rake gitlab:ldap:check
   
   # Check GitLab logs
   docker exec sso-gitlab tail -f /var/log/gitlab/gitlab-rails/production.log
   ```