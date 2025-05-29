#!/bin/bash
# Wait for at least one Consul node to be healthy

echo "Checking if Consul cluster is available..."

# Check if any Consul container is running and healthy
for i in {1..30}; do
  for node in consul-node1 consul-node2 consul-node3; do
    container="${DEPLOYMENT_NAME}-${node}"
    
    # Check if container exists and is running
    if docker ps --format "{{.Names}}" | grep -q "^${container}$"; then
      # Check if Consul is responding inside the container
      if docker exec "${container}" consul members >/dev/null 2>&1; then
        echo "✓ Consul cluster is available via ${container}"
        exit 0
      fi
    fi
  done
  
  echo "Waiting for Consul cluster... ($i/30)"
  sleep 2
done

echo "Warning: Could not verify Consul cluster, proceeding anyway"
exit 0