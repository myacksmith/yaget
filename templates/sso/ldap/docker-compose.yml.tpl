services:
  ${SERVICE_NAME}:
    image: "osixia/openldap:${LDAP_VERSION}"
    container_name: "${CONTAINER_NAME}"
    hostname: "${HOSTNAME}"
    environment:
      - LDAP_ORGANISATION=${LDAP_ORGANISATION}
      - LDAP_DOMAIN=${LDAP_DOMAIN}
      - LDAP_ADMIN_PASSWORD=${LDAP_ADMIN_PASSWORD}
    volumes:
      - "${SERVICE_DIR}/ldif:/container/service/slapd/assets/config/bootstrap/ldif/custom:rw"
      - "${SERVICE_DIR}/volumes/data:/var/lib/ldap:rw"
      - "${SERVICE_DIR}/volumes/config:/etc/ldap/slapd.d:rw"
    networks:
      - "${NETWORK_NAME}"
    ports:
      - "389"
      - "636"

networks:
  ${NETWORK_NAME}:
    external: true
