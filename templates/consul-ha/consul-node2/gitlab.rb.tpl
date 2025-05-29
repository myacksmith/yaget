# Consul Node 2 Configuration
roles ["consul_role"]

# Node configuration
node_exporter["enable"] = true

# Consul configuration
consul["enable"] = true
consul["configuration"] = {
  server: true,
  bootstrap_expect: 3,
  datacenter: "gitlab-dc",
  node_name: "${SERVICE_NAME}",
  bind_addr: "0.0.0.0",
  client_addr: "0.0.0.0",
  retry_join: %w[${DEPLOYMENT_NAME}-consul-node1 ${DEPLOYMENT_NAME}-consul-node2 ${DEPLOYMENT_NAME}-consul-node3],
  ui: true
}

# Monitoring
consul["monitoring_service_discovery"] = true
gitlab_rails['auto_migrate'] = false
