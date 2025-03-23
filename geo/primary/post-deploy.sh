!#/bin/bash

# Wait for the instance to be up and operational
GITLAB_URL="http://$DEPLOYMENT_NAME-$SERVICE_NAME.local"
READINESS_URL="${GITLAB_URL}/-/readiness"
TIMEOUT=300 # 5 mins

check_readiness() {
  echo "Checking if GitLab container is ready"

  start_time=$(date +%s)
  end_time=$((start_time + TIMEOUT))

  while [[ $(date +%s) -lt $end_time ]]; do
    # Check if container is running
    if ! docker ps | grep -q "$CONTAINER_NAME"; then
      echo "Waiting for GitLab container to start... $(($end_time - $(date +%s))) seconds remaining"
      sleep 10
      continue
    fi

    # Check readiness endpoint
    http_status=$(curl -s -o /dev/null -w "%{http_code}" "$READINESS_URL")

    if [[ "$http_status" == "200" ]]; then
      echo "GitLab is ready!"
      exit 0
    else
      echo "Waiting for GitLab services to initialize... $(($end_time - $(date +%s))) seconds remaining"
      echo "Current status: $http_status"
      sleep 10
      continue
    fi
  done

  echo "Timeout reached. GitLab is not ready after $TIMEOUT seconds."
  exit 1
}

# Set up primary node as geo primary
check_readiness 
docker exec $CONTAINER_NAME gitlab-ctl set-geo-primary


