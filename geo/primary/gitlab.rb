# Primary Geo node configuration
external_url 'http://geo-primary.local'

# Enable Geo primary role
gitlab_rails['geo_node_name'] = 'geo-primary'
gitlab_rails['geo_primary_role'] = true
gitlab_rails['initial_license_file'] = './Gitlab.gitlab-license'
