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

      packages = with pkgs; {
        default = writeShellApplication {
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

        dispose = writeShellApplication {
          name = "teardown-swarm.sh";
          runtimeInputs = packages;

          text = ''
            set -e

            echo "Running disposal scripts..."

            echo "Disposing public services..."
            ./public/dispose.sh

            echo "Disposing tailnet exclusive services..."
            # ./tail/dispose.sh

            echo "Disposing admin services..."
            ./admin/dispose.sh
          '';
        };
      };

      devShells.default = pkgs.mkShell {
        DOMAIN_NAME = "localhost";

        inherit packages;
      };
    });
}
