#!/usr/bin/env bash

# This script initializes and deploys the Authentik stack using Docker Swarm.
# It creates necessary Docker secrets and networks if they do not already exist.
# Exit immediately if a command exits with a non-zero status
set -e

AUTHENTIK_DB_OWNER_PASSWORD=$(openssl rand -base64 32 | tr -d '\n')
AUTHENTIK_SECRET_KEY=$(openssl rand -base64 60 | tr -d '\n')

# Create Docker secrets if they do not already exist
if ! docker secret ls | grep -q authentik_db_owner_password; then
    echo "$AUTHENTIK_DB_OWNER_PASSWORD" | docker secret create authentik_db_owner_password -
    echo "Created Docker secret: authentik_db_owner_password"
else
    echo "Docker secret authentik_db_owner_password already exists"
fi

if ! docker secret ls | grep -q authentik_secret_key; then
    echo "$AUTHENTIK_SECRET_KEY" | docker secret create authentik_secret_key -
    echo "Created Docker secret: authentik_secret_key"
else
    echo "Docker secret authentik_secret_key already exists"
fi

docker stack deploy -c ./authentik/docker-compose.yml authentik \
    || { echo "Failed to deploy Authentik stack"; exit 1; }

echo "Authentik stack deployed successfully."
