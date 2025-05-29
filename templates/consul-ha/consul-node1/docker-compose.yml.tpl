services:
  ${SERVICE_NAME}:
    image: gitlab/gitlab-ee:${GITLAB_VERSION}
    container_name: ${CONTAINER_NAME}
    hostname: ${HOSTNAME}
    restart: unless-stopped
    networks:
      - ${NETWORK_NAME}
    volumes:
      - "${CONFIG_PATH}/gitlab.rb:/etc/gitlab/gitlab.rb"
      - "${SERVICE_DIR}/volumes/config:/etc/gitlab"
      - "${SERVICE_DIR}/volumes/logs:/var/log/gitlab"
      - "${SERVICE_DIR}/volumes/data:/var/opt/gitlab"

networks:
  ${NETWORK_NAME}:
    external: true
