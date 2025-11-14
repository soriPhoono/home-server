#!/usr/bin/env bash

set -e

if [[ ! -d ./secrets ]]; then
    mkdir ./secrets
fi

read -srp "Enter your Cloudflare API Token: " cf_token

echo
echo "Using Cloudflare API Token: ****${cf_token: -4}"
echo "$cf_token" | tee ./secrets/cloudflare_api_token.txt > /dev/null

echo
echo "Cloudflare API Token saved to ./secrets/cloudflare_api_token.txt"

# Execute stack
docker stack deploy -c ./portainer/docker-compose.yml portainer \
    || { echo "Failed to deploy Portainer stack"; exit 1; }

echo "Portainer stack deployed successfully."
