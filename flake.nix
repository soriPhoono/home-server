{
  description = "Empty flake with basic devshell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs @ {
    nixpkgs,
    flake-utils,
    ...
  }: let
    lib = nixpkgs.lib;
  in
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};

      dependencies = with pkgs; [
          k3d
          kubectl
          kubernetes-helm
        ];
    in {
      packages.spawnTestEnv = pkgs.writeShellApplication {
        name = "spawn-test-env.sh";

        runtimeInputs = dependencies;

        text = ''
          set -euo pipefail

          CLUSTER_NAME=$1

          k3d cluster create "$CLUSTER_NAME" \
              --servers 3 \
              --agents 6 \
              --volume "/dev/mapper/crypted:/dev/mapper/crypted@all" \
              --volume "/sys/fs/cgroup:/sys/fs/cgroup@all" \
              --k3s-arg "--kubelet-arg=fail-swap-on=false@all"
        '';
      };

      devShells.default = pkgs.mkShell {
        packages = dependencies;
      };
    });
}
