#!/usr/bin/env bash

# This script initializes and deploys the Authentik stack using Docker Swarm.
# It creates necessary Docker secrets and networks if they do not already exist.
# Exit immediately if a command exits with a non-zero status
set -e

AUTHENTIK_DB_OWNER_PASSWORD=$(openssl rand -base64 32 | tr -d '\n') \
    AUTHENTIK_SECRET_KEY=$(openssl rand -base64 60 | tr -d '\n') \
    docker stack deploy -c ./authentik/docker-compose.yml authentik \
    || { echo "Failed to deploy Authentik stack"; exit 1; }

echo "Authentik stack deployed successfully."
