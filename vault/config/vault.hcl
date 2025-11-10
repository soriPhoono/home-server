# Storage configuration (This is where secrets are saved)
storage "file" {
  path = "/vault/data"
}

# Listener configuration (This is how we talk to Vault)
listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = "false" # Disable TLS for initial setup simplicity, BUT ENABLE FOR PRODUCTION
}

# Enable the Web UI
ui = true

# Memory locking is critical for production security
# Ensure the Docker container has the IPC_LOCK capability added
disable_mlock = false
