#!/usr/bin/env bash

# This script initializes and deploys the Portainer stack with necessary Docker secrets and networks.
# It checks for the existence of required Docker secrets and networks, creating them if they do not exist.
# Finally, it deploys the Portainer stack using Docker Swarm.
# Ensure you have the necessary environment variables set before running this script.
# - CLOUDFLARE_API_TOKEN: Your Cloudflare API token for creating the portainer_cf_token secret.
# Exit immediately if a command exits with a non-zero status
set -e

# Create cloudflare secret api key if it doesn't exist
if ! docker secret ls --format '{{.Name}}' | grep -q "^portainer_cf_token$"; then
    if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
        echo "portainer_cf_token environment variable is not set. Cannot create portainer_cf_token secret."
        exit 1
    fi
    echo "Creating Docker secret: portainer_cf_token"
    echo -n "$CLOUDFLARE_API_TOKEN" | docker secret create portainer_cf_token -
else
    echo "Docker secret portainer_cf_token already exists. Skipping creation."
fi

# Create networks for stack
NETWORKS=("portainer_traefik-public")

for NETWORK in "${NETWORKS[@]}"; do
    if ! docker network ls --format '{{.Name}}' | grep -q "^${NETWORK}$"; then
        echo "Creating Docker network: ${NETWORK}"
        docker network create "${NETWORK}"
    else
        echo "Docker network ${NETWORK} already exists. Skipping creation."
    fi
done

# Execute stack
docker stack deploy -c ./docker-compose.yml portainer || { echo "Failed to deploy Portainer stack"; exit 1; }

echo "Portainer stack deployed successfully."
