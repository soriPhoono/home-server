{
  description = "Empty flake with basic devshell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    agenix-shell.url = "github:aciceri/agenix-shell";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      lib = pkgs.lib;

      agenixInstallationScript = inputs.agenix-shell.lib.installationScript system {
        secrets = {
          DOCKER_USERNAME.file = ./secrets/docker_username.age;
          DOCKER_PASSWORD.file = ./secrets/docker_password.age;
        };
      };

      treefmtForSystem = inputs.treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
    in {
      formatter = treefmtForSystem.config.build.wrapper;

      checks.formatting = treefmtForSystem.config.build.check self;

      packages = {
        init-dev-cluster = pkgs.writeShellApplication {
          name = "init-dev-cluster";

          runtimeInputs = with pkgs; [
            k3d
            kubectl
            fluxcd
          ];

          text = ''
            set -euo pipefail

            k3d cluster create homelab-dev \
              -s 3 -a 6 \
              --volume "/dev/mapper/crypted:/dev/mapper/crypted@all" \
              --k3s-arg "--kubelet-arg=fail-swap-on=false@all" \
              --image rancher/k3s:latest \
              --port "80:80@loadbalancer" \
              --port "443:443@loadbalancer"

            kubectl wait --for=condition=Ready nodes --all --timeout=120s

            read -rp "Enter your github username here: " GITHUB_USERNAME
            read -rp "Enter your github repository name here: " GITHUB_REPO
            read -rp "Enter the branch you want to bootstrap to (e.g. main): " GITHUB_BRANCH

            flux bootstrap github \
              --owner="$GITHUB_USERNAME" \
              --repository="$GITHUB_REPO" \
              --branch="$GITHUB_BRANCH" \
              --path=clusters/dev \
              --personal
          '';
        };

        init-prod-cluster = pkgs.writeShellApplication {
          name = "init-prod-cluster";

          runtimeInputs = with pkgs; [
            fluxcd
          ];

          text = ''
            set -euo pipefail

            read -rp "Enter your github username here: " GITHUB_USERNAME
            read -rp "Enter your github repository name here: " GITHUB_REPO
            read -rp "Enter the branch you want to bootstrap to (e.g. main): " GITHUB_BRANCH

            flux bootstrap github \
              --owner="$GITHUB_USERNAME" \
              --repository="$GITHUB_REPO" \
              --branch="$GITHUB_BRANCH" \
              --path=clusters/prod \
              --personal
          '';
        };
      };

      devShells.default = with pkgs;
        mkShell {
          packages = [
            k3d
            kubectl
            kubernetes-helm
            helmfile
            fluxcd

            age
          ];

          shellHook = ''
            # 1. Define paths
            SSH_KEY="$HOME/.ssh/id_ed25519"
            USER_SECRET="./secrets/docker_username.age"
            PASS_SECRET="./secrets/docker_password.age"

            # 2. Check if files exist
            if [ -f "$SSH_KEY" ] && [ -f "$USER_SECRET" ] && [ -f "$PASS_SECRET" ]; then
              echo "Decrypting secrets..."
              
              # 3. Decrypt directly into environment variables
              # We suppress stderr (2>/dev/null) to hide key warnings, 
              # but if it fails, the var will just be empty.
              export DOCKER_USERNAME=$(age -d -i "$SSH_KEY" "$USER_SECRET")
              export DOCKER_PASSWORD=$(age -d -i "$SSH_KEY" "$PASS_SECRET")
              
              if [ -n "$DOCKER_USERNAME" ]; then
                 echo "Secrets loaded! Docker User: $DOCKER_USERNAME"
              else
                 echo "Decryption failed. Check your SSH key passphrase?"
              fi
            else
              echo "Warning: Secrets or SSH key not found. Skipping decryption."
            fi
          '';
        };
    });
}
