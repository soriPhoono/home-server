#!/usr/bin/env bash

# This script initializes and deploys the Postgres and Redis containers alongside Adminer using Docker Swarm.
# It creates necessary Docker secrets and networks if they do not already exist.
# It then deploys the stack using the provided docker-compose.yml file.
# Exit immediately if a command exits with a non-zero status
set -e

# Create Docker secrets if they do not exist
NAMES=("authentik_db_owner_password" "authentik_secret_key")
VALUES=("$(openssl rand -base64 36 | tr -d '\n')" "$(openssl rand -base64 60 | tr -d '\n')")
for i in "${!NAMES[@]}"; do
    NAME="${NAMES[$i]}"
    VALUE="${VALUES[$i]}"
    if ! docker secret ls --format '{{.Name}}' | grep -q "^$NAME$"; then
        echo "Creating Docker secret: $NAME"
        echo "$VALUE" | docker secret create "$NAME" -
    else
        echo "Docker secret $NAME already exists. Skipping creation."
    fi
done

# Create networks for stack if they do not exist
NETWORKS=()

for NETWORK in "${NETWORKS[@]}"; do
    if ! docker network ls --format '{{.Name}}' | grep -q "^${NETWORK}$"; then
        echo "Creating Docker network: ${NETWORK}"
        docker network create "${NETWORK}"
    else
        echo "Docker network ${NETWORK} already exists. Skipping creation."
    fi
done

# Execute stack
docker stack deploy -c ./authentik/docker-compose.yml authentik || { echo "Failed to deploy Authentik stack"; exit 1; }

echo "Authentik stack deployed successfully."
