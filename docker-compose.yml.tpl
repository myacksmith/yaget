# Default docker-compose template for YAGET
# This template is used when no custom template is provided for a service

services:
  ${SERVICE_NAME}:
    image: "gitlab/gitlab-ee:${GITLAB_VERSION}"
    container_name: "${CONTAINER_NAME}"
    hostname: "${HOSTNAME}"
    restart: unless-stopped
    environment:
      GITLAB_OMNIBUS_CONFIG: "from_file('/etc/gitlab/gitlab.rb')"
    volumes:
      # Configuration file
      - "${CONFIG_PATH}/gitlab.rb:/etc/gitlab/gitlab.rb:ro"
      # Data volumes using bind mounts
      - "${SERVICE_DIR}/volumes/config:/etc/gitlab"
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