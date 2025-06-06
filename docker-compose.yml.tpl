# Default docker-compose template for YAGET
# This template is used when no custom template is provided for a service

services:
  ${SERVICE_NAME}:
    image: "gitlab/gitlab-ee:${GITLAB_VERSION}"
    container_name: "${CONTAINER_NAME}"
    hostname: "${HOSTNAME}"
    restart: unless-stopped
    # GITLAB_OMNIBUS_CONFIG removed - GitLab automatically reads /etc/gitlab/gitlab.rb
    volumes:
      # Template-provided configuration (writable for testing)
      - "${CONFIG_PATH}/gitlab.rb:/etc/gitlab/gitlab.rb"
      
      # Runtime configuration directory (for GitLab-generated files)
      # Note: Individual file mounts above take precedence over files in this directory
      - "${SERVICE_DIR}/volumes/config:/etc/gitlab"
      
      # Data volumes using bind mounts
      - "${SERVICE_DIR}/volumes/logs:/var/log/gitlab"
      - "${SERVICE_DIR}/volumes/data:/var/opt/gitlab"
    networks:
      - "${NETWORK_NAME}"
    ports:
      - "80"    # Docker assigns random host port
      - "443"   # Docker assigns random host port
      - "22"    # Docker assigns random host port
    shm_size: '256m'
    healthcheck:
      test: ["CMD", "/opt/gitlab/bin/gitlab-healthcheck", "--fail", "--max-time", "10"]
      interval: 30s
      timeout: 15s
      retries: 5
      start_period: 60s

networks:
  ${NETWORK_NAME}:
    external: true