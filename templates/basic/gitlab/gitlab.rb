# Basic GitLab configuration
external_url "${EXTERNAL_URL}"

# Resource optimization for testing
puma["worker_processes"] = 2
puma["min_threads"] = 1
puma["max_threads"] = 4

postgresql["shared_buffers"] = "256MB"
postgresql["max_worker_processes"] = 4

# Disable unnecessary services for testing
gitlab_pages["enable"] = false
registry["enable"] = false
gitlab_kas["enable"] = false

# Set time zone
gitlab_rails["time_zone"] = "UTC"
