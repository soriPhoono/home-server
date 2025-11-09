#!/usr/bin/env bash
set -e

# --- Configuration Section ---

# 1. Read services from the environment variable (space-separated string)
# Example: SERVICES="funkwhale_service auth_service analytics_service"
# We convert the space-separated string into a bash array.
if [ -z "$SERVICES" ]; then
    echo "ERROR: The SERVICES environment variable is not set or empty. Exiting." >&2
    exit 1
fi

# Convert space-separated string ENV var into a bash array
read -r -a SERVICES <<< "$SERVICES"

echo "Detected services: ${SERVICES[@]}"

# --- Execution Section ---

echo "--- Starting PostgreSQL Multi-Database and User Initialization ---"

if [ -z "$POSTGRES_PASSWORD" ]; then
    echo "ERROR: The POSTGRES_PASSWORD environment variable is not set. Exiting." >&2
    exit 1
fi

export PGPASSWORD="$POSTGRES_PASSWORD"

for SERVICE_PREFIX in "${SERVICES[@]}"; do
    echo "Preparing database for service: $SERVICE_PREFIX"

    DB_NAME="${SERVICE_PREFIX}"
    USER_NAME="${SERVICE_PREFIX}_user"
    PASSWORD_VAR_NAME="${SERVICE_PREFIX^^}_PASSWORD"
    PASSWORD_VALUE="${!PASSWORD_VAR_NAME}"

    if [ -z "$PASSWORD_VALUE" ]; then
        echo "Error: Password for $USER_NAME is not set. Please define the environment variable $PASSWORD_VAR_NAME."
        exit 1
    fi

    echo "Processing service: $SERVICE_PREFIX (DB: $DB_NAME, User: $USER_NAME)"

    # 4. Connect to the existing 'postgres' default database using the superuser
    # and execute both CREATE USER and CREATE DATABASE.
    # NOTE: The SQL is wrapped in a DDL block to gracefully handle existing users/databases
    # if the volume data is accidentally preserved, though `set -e` ensures exit on error.
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "postgres" <<-EOSQL
      
      -- Create user with dynamic password
      CREATE USER ${USER_NAME} WITH PASSWORD '${PASSWORD_VALUE}';
      
      -- Create database and set owner
      CREATE DATABASE ${DB_NAME} OWNER ${USER_NAME};
      
      -- Grant privileges
      GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${USER_NAME};
EOSQL

    echo "Service $SERVICE_PREFIX initialized successfully."
done

unset PGPASSWORD

echo "--- All databases and users created. Initialization complete. ---"