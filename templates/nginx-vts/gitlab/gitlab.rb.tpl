# Nginx VTS Test Configuration
external_url 'http://${HOSTNAME}'

# Nginx with VTS module
nginx['redirect_http_to_https'] = false
nginx['listen_https'] = false
nginx['status'] = {
  "enable" => true,
  "listen_addresses" => ["0.0.0.0"],
  "fqdn" => "${HOSTNAME}",
  "port" => 9999,
  "vts_enable" => true,
  "options" => {
    "server_tokens" => "off",
    "access_log" => "off",
    "allow" => ["0.0.0.0/0"]  # Allow from anywhere
  }
}

# Test custom VTS histogram configuration
nginx['custom_gitlab_server_config'] = "vhost_traffic_status_histogram_buckets 0.005 0.01 0.05 0.1 0.5 1 2.5 5 10;"

# Enable exporters
prometheus['enable'] = false
node_exporter['enable'] = true
node_exporter['listen_address'] = '0.0.0.0:9100'
redis_exporter['enable'] = true
redis_exporter['listen_address'] = '0.0.0.0:9121'
postgres_exporter['enable'] = true
postgres_exporter['listen_address'] = '0.0.0.0:9187'
gitlab_exporter['enable'] = true
gitlab_exporter['listen_address'] = '0.0.0.0'
gitlab_exporter['listen_port'] = '9168'
puma['exporter_enabled'] = true
puma['exporter_address'] = "0.0.0.0"
puma['exporter_port'] = 8083
sidekiq['metrics_enabled'] = true
sidekiq['listen_address'] = "0.0.0.0"
sidekiq['listen_port'] = 8082
gitlab_workhorse['prometheus_listen_addr'] = "0.0.0.0:9229"
gitaly['configuration'] = {
  prometheus_listen_addr: '0.0.0.0:9236',
}

# Disable unused services
gitlab_kas['enable'] = false
gitlab_pages['enable'] = false
registry['enable'] = false

puma['worker_processes'] = 2
postgresql['shared_buffers'] = "256MB"
