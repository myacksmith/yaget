# YAGET Templates

This directory contains deployment templates for YAGET.

## Structure

Each subdirectory represents a deployment configuration:

```
templates/
├── basic/          # Simple single GitLab instance
├── sso/           # GitLab with LDAP authentication
└── ha/            # High-availability setup (example)
```

## Using Templates

```bash
# Deploy using a template
./deploy.sh basic

# With custom GitLab version
GITLAB_VERSION=16.0.0 ./deploy.sh basic
```

## Creating Your Own Templates

1. Create a new directory: `mkdir templates/my-deployment`
2. Add services as subdirectories
3. Add configuration files, templates, and scripts
4. Deploy with: `./deploy.sh my-deployment`

See [TEMPLATES.md](../TEMPLATES.md) for detailed documentation.

## External Templates

You can use templates from other locations:

```bash
YAGET_TEMPLATES_DIR=/path/to/my-templates ./deploy.sh custom
```

Or clone a templates repository here:

```bash
rm -rf templates
git clone https://github.com/your-org/yaget-templates.git templates
```

## Mixing Template Sources

Use symlinks to combine templates from multiple sources:

```bash
# Link individual templates
ln -s ~/work-templates/customer-reproduction templates/customer-reproduction
ln -s /shared/team-templates/stress-test templates/stress-test

# Link entire template collections
ln -s ~/personal-templates/* templates/

# Now all templates are available
ls templates/
# basic  sso  customer-reproduction  stress-test  my-custom  ...
```