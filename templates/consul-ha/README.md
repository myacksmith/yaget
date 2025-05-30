# GitLab Consul HA Template

Deploys a GitLab Consul cluster with 3 server nodes + 1 GitLab application node.

## Quick Start

```bash
# Deploy
./deploy.sh consul-ha

# Check status
docker exec consul-ha-consul-node1 consul members

# Destroy
./destroy.sh consul-ha
```

## Services

- **consul-node1**, **consul-node2**, **consul-node3**: Consul servers with `roles ['consul_role']`
- **gitlab-app**: GitLab application with Consul client

## Configuration

- `.env`: Set GitLab version (default: 17.3.7-ee.0)
- `*/gitlab.rb`: Service configurations (processed as templates)
- `*/docker-compose.yml.tpl`: Container definitions

## Notes

- Consul nodes communicate using container names
- No static IPs required
- Consul cluster auto-forms via `retry_join`
- All data persists in `artifacts/consul-ha/`