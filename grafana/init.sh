#!/usr/bin/env bash

# This script initializes and deploys the Monitoring stack using Docker Swarm.
# It creates necessary Docker secrets and networks if they do not already exist.
# Exit immediately if a command exits with a non-zero status.
set -e

# Create Docker secrets if they do not exist
NAMES=()
VALUES=()
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
NETWORKS=("monitoring_default")
for NETWORK in "${NETWORKS[@]}"; do
    if ! docker network ls --format '{{.Name}}' | grep -q "^${NETWORK}$"; then
        echo "Creating Docker network: ${NETWORK}"
        docker network create --attachable --driver=overlay "${NETWORK}"
    else
        echo "Docker network ${NETWORK} already exists. Skipping creation."
    fi
done

# Execute stack
docker stack deploy -c ./grafana/docker-compose.yml monitoring || { echo "Failed to deploy Monitoring stack"; exit 1; }

echo "Monitoring stack deployed successfully."
