#!/bin/bash
set -e

CONTAINER="${DEPLOYMENT_NAME}-${SERVICE_NAME}"

echo "Waiting for nginx to start..."
until docker exec ${CONTAINER} gitlab-ctl status | grep -E "run: nginx:" >/dev/null 2>&1; do
  sleep 5
done
echo "Nginx is running"

# Get the nginx status port
PORT=$(docker port ${CONTAINER} 9999 | cut -d ":" -f 2)

echo "Waiting for nginx status port..."
"${SCRIPT_DIR}/lib/wait-for-it.sh" localhost:${PORT} -t 60

echo "Waiting for VTS metrics endpoint..."
until curl -sf http://localhost:${PORT}/metrics >/dev/null 2>&1; do
  sleep 2
done
echo "Metrics endpoint is ready"

echo ""
echo "=== GitLab Nginx VTS Metrics ==="
curl -s http://localhost:${PORT}/metrics

echo ""
echo "=== VTS-specific metrics ==="
curl -s http://localhost:${PORT}/metrics | grep nginx_vts

echo ""
echo "=== Histogram buckets ==="
curl -s http://localhost:${PORT}/metrics | grep -E "nginx_vts.*bucket" || echo "No histogram buckets found"

echo ""
echo "=== All VTS metrics with line numbers ==="
curl -s http://localhost:${PORT}/metrics | grep nginx_vts | nl

echo ""
echo "=== Test complete ==="
echo "VTS metrics endpoint: http://localhost:${PORT}/metrics"
