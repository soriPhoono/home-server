#!/usr/bin/env bash

# This script initializes and deploys the Authentik stack using Docker Swarm.
# It creates necessary Docker secrets and networks if they do not already exist.
# Exit immediately if a command exits with a non-zero status
set -e

echo "Initializing Authentik stack..."

# Create Docker secrets if they do not already exist
if ! docker secret ls | grep -q auth_authentik-db-owner-password; then
    AUTHENTIK_DB_OWNER_PASSWORD=$(openssl rand -base64 32 | tr -d '\n')
    echo "Using generated Authentik DB owner password: ****${AUTHENTIK_DB_OWNER_PASSWORD: -4}"
    echo "$AUTHENTIK_DB_OWNER_PASSWORD" | docker secret create auth_authentik-db-owner-password -
    echo "Created Docker secret: auth_authentik-db-owner-password"
else
    echo "Docker secret auth_authentik-db-owner-password already exists"
fi

if ! docker secret ls | grep -q auth_authentik-secret-key; then
    AUTHENTIK_SECRET_KEY=$(openssl rand -base64 60 | tr -d '\n')
    echo "Using generated Authentik secret key: ****${AUTHENTIK_SECRET_KEY: -4}"
    echo "$AUTHENTIK_SECRET_KEY" | docker secret create auth_authentik-secret-key -
    echo "Created Docker secret: auth_authentik-secret-key"
else
    echo "Docker secret auth_authentik-secret-key already exists"
fi

docker stack deploy -c ./public/auth/docker-compose.yml auth \
    || { echo "Failed to deploy Authentik stack"; exit 1; }

echo "Authentik stack deployed successfully."
echo