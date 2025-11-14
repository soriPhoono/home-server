#!/usr/bin/env bash

# This script initializes and deploys the Postgres and Redis containers alongside Adminer using Docker Swarm.
# It creates necessary Docker secrets and networks if they do not already exist.
# It then deploys the stack using the provided docker-compose.yml file.
# Exit immediately if a command exits with a non-zero status
set -e

# Create postgres password secret if it doesn't exist
POSTGRES_PASSWORD=$(openssl rand -base64 36 | tr -d '\n')

# Execute stack
docker stack deploy -c ./backend/docker-compose.yml backend || { echo "Failed to deploy Database stack"; exit 1; }

echo "Database stack deployed successfully."
