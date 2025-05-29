# GitLab Application Node Configuration
external_url "http://${HOSTNAME}"

# Consul client configuration (not server)
consul["enable"] = true
consul["configuration"] = {
  server: false,
  datacenter: "gitlab-dc",
  node_name: "${SERVICE_NAME}",
  bind_addr: "0.0.0.0",
  client_addr: "0.0.0.0",
  retry_join: %w[${DEPLOYMENT_NAME}-consul-node1 ${DEPLOYMENT_NAME}-consul-node2 ${DEPLOYMENT_NAME}-consul-node3]
}

# Enable monitoring service discovery via Consul
consul["monitoring_service_discovery"] = true
