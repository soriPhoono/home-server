#!/usr/bin/env bash

# This script initializes and deploys the Postgres and Redis containers alongside Adminer using Docker Swarm.
# It creates necessary Docker secrets and networks if they do not already exist.
# It then deploys the stack using the provided docker-compose.yml file.
# Exit immediately if a command exits with a non-zero status
set -e

echo "Initializing Database stack deployment..."

if [[ ! -d ./secrets ]]; then
    mkdir ./secrets
fi

# Create postgres password secret if it doesn't exist
if ! docker secret ls | grep -q 'backend_postgres-password'; then
    POSTGRES_PASSWORD=$(openssl rand -base64 36 | tr -d '\n')
    echo "Using generated Postgres password: ****${POSTGRES_PASSWORD: -4}"
    echo "$POSTGRES_PASSWORD" | docker secret create backend_postgres-password -
    echo "Created Docker secret: backend_postgres-password"
else
    echo "Docker secret 'backend_postgres-password' already exists. Skipping creation."
fi

# Execute stack
docker stack deploy -c ./admin/backend/docker-compose.yml backend \
    || { echo "Failed to deploy Database stack"; exit 1; }

echo "Database stack deployed successfully."
echo