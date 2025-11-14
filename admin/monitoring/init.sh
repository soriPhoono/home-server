#!/usr/bin/env bash

# This script initializes and deploys the Monitoring stack using Docker Swarm.
# It creates necessary Docker secrets and networks if they do not already exist.
# Exit immediately if a command exits with a non-zero status.
set -e

echo "Initializing Monitoring stack..."

# Execute stack
docker stack deploy -c ./admin/monitoring/docker-compose.yml monitoring || { echo "Failed to deploy Monitoring stack"; exit 1; }

echo "Monitoring stack deployed successfully."
echo