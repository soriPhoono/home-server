-- Create authentik database
CREATE DATABASE IF NOT EXISTS authentik;

-- Create authentik database user with password from environment variable AUTHENTIK_DB_PASSWORD
CREATE USER IF NOT EXISTS 'authentik'@'%' IDENTIFIED BY '${AUTHENTIK_DB_PASSWORD}';
GRANT ALL PRIVILEGES ON authentik.* TO 'authentik'@'%';