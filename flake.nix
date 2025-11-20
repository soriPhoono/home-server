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
    in {
      packages = {
        create-dev-cluster = pkgs.writeShellApplication {
          name = "create-dev-cluster";
          runtimeDependencies = with pkgs; [
          ];
          text = ''

          '';
        };
        init-prod-cluster = pkgs.writeShellApplication {
          name = "init-prod-cluster";
          runtimeInputs = with pkgs; [
            kubectl
            kubernetes-helm
            helmfile
            fluxcd
          ];
          text = ''
            read -rsp "Enter your github oauth token here: " GITHUB_TOKEN

            export GITHUB_TOKEN

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
