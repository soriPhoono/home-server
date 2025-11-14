{
  description = "Empty flake with basic devshell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};

      packages = with pkgs; [
        openssl
      ];
    in {
      formatter = pkgs.alejandra;

      packages.default = pkgs.writeShellApplication {
        name = "deploy-swarm.sh";
        runtimeInputs = packages;

        text = ''
          set -e

          echo "Running initialization scripts..."

          echo "Initializing admin services..."
          ./admin/init.sh

          echo "Initializing tailnet exclusive services..."
          # ./tail/init.sh

          echo "Initializing public services..."
          ./public/init.sh
        '';
      };

      devShells.default = pkgs.mkShell {
        DOMAIN_NAME = "localhost";

        inherit packages;
      };
    });
}
