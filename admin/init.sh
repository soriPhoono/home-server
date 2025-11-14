#!/usr/bin/env bash

set -e

echo "Initializing Admin Services with Portainer stack deployment..."

./admin/reverse-proxy/init.sh

# Execute stack
docker stack deploy -c ./admin/docker-compose.yml admin \
    || { echo "Failed to deploy Portainer stack"; exit 1; }

echo "Portainer stack deployed successfully."
echo

./admin/backend/init.sh
./admin/monitoring/init.sh