#!/usr/bin/env bash

set -e

echo "Initializing Traefik reverse proxy setup..."

if [[ ! -d ./secrets ]]; then
    mkdir ./secrets
fi

if ! docker secret ls | grep -q proxy_traefikcf-token; then
    read -srp "Enter your Cloudflare API Token: " CF_TOKEN
    echo "$CF_TOKEN" | docker secret create proxy_traefikcf-token - 
    echo "Docker secret 'proxy_traefikcf-token' created."
else
    echo "Docker secret 'proxy_traefikcf-token' already exists. Skipping creation."
fi

docker stack deploy -c ./admin/proxy/docker-compose.yml proxy

echo "Traefik reverse proxy setup completed."
echo