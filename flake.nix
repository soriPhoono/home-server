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

            # 1. Check if the variables exist
            if [ -z "''${DOCKER_USERNAME:-}" ] || [ -z "''${DOCKER_PASSWORD:-}" ]; then
              echo "WARNING: DOCKER_USERNAME or DOCKER_PASSWORD not set."
              echo "Cluster will be anonymous and may hit Docker Hub rate limits."
              REGISTRY_FLAG=""
            else
              echo "Configuring cluster with Docker Hub credentials for user: $DOCKER_USERNAME"

              # 2. Generate the K3s registry configuration file
              cat <<EOF > registries.yaml
            configs:
              "docker.io":
                auth:
                  username: "$DOCKER_USERNAME"
                  password: "$DOCKER_PASSWORD"
            EOF

              # 3. Prepare the flag for k3d
              REGISTRY_FLAG="--registry-config=./registries.yaml"
            fi

            # 4. Create the cluster (injecting the flag)
            k3d cluster create homelab-dev \
              -s 3 -a 6 \
              --volume "/dev/mapper/crypted:/dev/mapper/crypted@all" \
              --k3s-arg "--kubelet-arg=fail-swap-on=false@all" \
              --image rancher/k3s:latest \
              --port "80:80@loadbalancer" \
              --port "443:443@loadbalancer" \
              "$REGISTRY_FLAG"  # <--- The flag is used here

            # 5. Clean up the sensitive file
            rm -f registries.yaml

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
