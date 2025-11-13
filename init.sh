#!/usr/bin/env bash

# This script initializes and deploys the complete server stack with necessary Docker secrets and networks.
# It checks for the existence of required Docker secrets and networks, creating them if they do not exist.
# Finally, it deploys the server stack using Docker Swarm.
# Ensure you have the necessary environment variables set before running this script.
# - CLOUDFLARE_API_TOKEN: Your Cloudflare API token for creating the portainer_cf_token secret.
# Exit immediately if a command exits with a non-zero status
set -e

./portainer/init.sh

echo "Server stack deployed successfully."