services:
  ${SERVICE_NAME}:
    image: "gitlab/gitlab-ee:${GITLAB_VERSION}"
    container_name: "${CONTAINER_NAME}"
    hostname: "${HOSTNAME}"
    restart: unless-stopped
    volumes:
      - "${CONFIG_PATH}/gitlab.rb:/etc/gitlab/gitlab.rb"
      - "${SERVICE_DIR}/volumes/config:/etc/gitlab"
      - "${SERVICE_DIR}/volumes/logs:/var/log/gitlab"
      - "${SERVICE_DIR}/volumes/data:/var/opt/gitlab"
    networks:
      - "${NETWORK_NAME}"
    ports:
      - "80"
      - "443"
      - "9999"
      - "9100"
      - "9121"
      - "9187"
      - "9168"
      - "8083"
      - "8082"
      - "9229"
      - "9236"

networks:
  ${NETWORK_NAME}:
    external: true