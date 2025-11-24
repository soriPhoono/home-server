{
  description = "Empty flake with basic devshell";

  inputs = {
    systems.url = "github:nix-systems/x86_64-linux";

    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    agenix.url = "github:ryantm/agenix";
    agenix-shell.url = "github:aciceri/agenix-shell";

    treefmt-nix.url = "github:numtide/treefmt-nix";

    git-hooks-nix.url = "github:cachix/git-hooks.nix";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = with inputs; [
        agenix-shell.flakeModules.default
        treefmt-nix.flakeModule
        git-hooks-nix.flakeModule
      ];
      systems = with inputs; import systems;
      agenix-shell = {
        secrets = {
          CLOUDFLARE_EMAIL.file = ./secrets/cloudflare_email.age;
          CLOUDFLARE_API_KEY.file = ./secrets/cloudflare_api_key.age;

          POSTGRES_PASSWORD.file = ./secrets/postgres_password.age;

          AUTHENTIK_DB_PASSWORD.file = ./secrets/authentik_db_password.age;
          AUTHENTIK_SECRET_KEY.file = ./secrets/authentik_secret_key.age;
        };
      };
      perSystem = {
        system,
        pkgs,
        config,
        lib,
        ...
      }:
        with pkgs;
        with lib; rec {
          packages = {
            default = pkgs.writeShellApplication {
              name = "deploy-script";

              runtimeInputs = with pkgs; [
                docker
              ];

              text = ''
                set -euo pipefail

                docker compose -f ./docker/admin/proxy/docker-compose.yml up -d
                docker compose -f ./docker/admin/docker-compose.yml up -d
                docker compose -f ./docker/admin/dns/docker-compose.yml up -d

                docker compose -f ./docker/admin/monitoring/docker-compose.yml up -d

                docker compose -f ./docker/admin/backend/docker-compose.yml up -d
              '';
            };

            teardown = pkgs.writeShellApplication {
              name = "teardown-script";

              runtimeInputs = with pkgs; [
                docker
              ];

              text = ''
                set -euo pipefail

                docker compose -f ./docker/admin/backend/docker-compose.yml down

                docker compose -f ./docker/admin/monitoring/docker-compose.yml down

                docker compose -f ./docker/admin/dns/docker-compose.yml down
                docker compose -f ./docker/admin/docker-compose.yml down
                docker compose -f ./docker/admin/proxy/docker-compose.yml down
              '';
            };
          };

          devShells.default = mkShell {
            packages = [
              inputs.agenix.packages.${system}.default
            ];

            shellHook = ''
              source ${lib.getExe config.agenix-shell.installationScript}

              ${config.pre-commit.shellHook}
            '';
          };

          treefmt.programs = {
            alejandra.enable = true;
            deadnix.enable = true;
            statix.enable = true;

            yamlfmt.enable = true;
          };

          pre-commit = {
            check.enable = true;
            settings.hooks = {
              nil.enable = true;

              treefmt.enable = true;
            };
          };
        };
    };
}
