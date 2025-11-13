#!/usr/bin/env bash

# This script initializes and deploys the Postgres and Redis containers alongside Adminer using Docker Swarm.
# It creates necessary Docker secrets and networks if they do not already exist.
# It then deploys the stack using the provided docker-compose.yml file.
# Exit immediately if a command exits with a non-zero status
set -e

# Create postgres password secret if it doesn't exist
NAME="postgres_password"
VALUE=$(openssl rand -base64 36 | tr -d '\n')
if ! docker secret ls --format '{{.Name}}' | grep -q "^$NAME$"; then
    echo "Creating Docker secret: $NAME"
    echo "$VALUE" | docker secret create $NAME -
else
    echo "Docker secret $NAME already exists. Skipping creation."
fi

# Create networks for stack
NETWORKS=("backend_default")

for NETWORK in "${NETWORKS[@]}"; do
    if ! docker network ls --format '{{.Name}}' | grep -q "^${NETWORK}$"; then
        echo "Creating Docker network: ${NETWORK}"
        docker network create --attachable --driver=overlay "${NETWORK}"
    else
        echo "Docker network ${NETWORK} already exists. Skipping creation."
    fi
done

# Execute stack
docker stack deploy -c ./backend/docker-compose.yml backend || { echo "Failed to deploy Database stack"; exit 1; }

echo "Database stack deployed successfully."
