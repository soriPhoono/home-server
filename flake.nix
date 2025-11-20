{
  description = "Empty flake with basic devshell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

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

            k3d cluster create homelab-dev \
              -s 3 -a 6 \
              --volume "/dev/mapper/crypted:/dev/mapper/crypted@all" \
              --k3s-arg "--kubelet-arg=fail-swap-on=false@all" \
              --image rancher/k3s:latest

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

        create-dev-cluster = pkgs.writeShellApplication {
          name = "create-dev-cluster";

          runtimeInputs = with pkgs; [
            k3d
          ];

          text = ''
            set -euo pipefail

            k3d cluster create homelab-dev \
              -s 3 -a 6 \
              --volume "/dev/mapper/crypted:/dev/mapper/crypted@all" \
              --k3s-arg "--kubelet-arg=fail-swap-on=false@all" \
              --image rancher/k3s:latest

            echo "Waiting for all nodes to become Ready..."
            kubectl wait --for=condition=Ready nodes --all --timeout=120s

            if [ ! -d "clusters/dev/flux-system" ]; then
              echo "ERROR: clusters/dev/flux-system does not exist."
              echo "Make sure you've bootstrapped Flux at least once (e.g. with nix run .#create-dev-cluster),"
              echo "and pulled the generated manifests to this repo."
              exit 1
            fi

            echo "Applying Flux system manifests from clusters/dev/flux-system..."
            kubectl apply -f clusters/dev/flux-system/

            echo "Waiting for Flux controllers to become Ready..."
            kubectl rollout status deployment/source-controller -n flux-system --timeout=180s
            kubectl rollout status deployment/kustomize-controller -n flux-system --timeout=180s
            kubectl rollout status deployment/helm-controller -n flux-system --timeout=180s
            kubectl rollout status deployment/notification-controller -n flux-system --timeout=180s

            echo "Flux controllers are Ready. They will now reconcile according to clusters/dev."
          '';
        };

        dispose-dev-cluster = pkgs.writeShellApplication {
          name = "dispose-dev-cluster";

          runtimeInputs = with pkgs; [
            k3d
          ];

          text = ''
            set -euo pipefail

            k3d cluster delete homelab-dev
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
          ];
        };
    });
}
