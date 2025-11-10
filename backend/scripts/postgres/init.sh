#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Generate a strong, 32-character random password
# We use 'tr' to remove special characters that might break in SQL/URLs
VAULT_ADMIN_PASS=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)

# --- PRINT THE PASSWORD TO THE CONSOLE ---
# This is the crucial part for your automation.
# You can 'grep' for this line in your logs.
echo "------------------------------------------------"
echo "---"
echo "--- GENERATED VAULT_ADMIN PASSWORD: $VAULT_ADMIN_PASS"
echo "---"
echo "------------------------------------------------"

# Run the SQL commands to create the user and grant permissions
# Note: We are using the default 'postgres' superuser to create this new role.
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE ROLE vault_admin WITH LOGIN PASSWORD '$VAULT_ADMIN_PASS';
    ALTER ROLE vault_admin CREATEROLE;

    -- Grant broad permissions. Adjust these to be more restrictive if needed.
    GRANT pg_write_all_data TO vault_admin;
    GRANT pg_read_all_data TO vault_admin;
EOSQL