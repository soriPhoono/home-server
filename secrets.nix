let
  soriphoono = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEgxxFcqHVwYhY0TjbsqByOYpmWXqzlVyGzpKjqS8mO7";

  keys = [soriphoono];
in {
  "secrets/cloudflare_email.age".publicKeys = keys;
  "secrets/cloudflare_api_token.age".publicKeys = keys;

  "secrets/postgres_password.age".publicKeys = keys;

  "secrets/authentik_db_password.age".publicKeys = keys;
  "secrets/authentik_secret_key.age".publicKeys = keys;
}
