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
      lib = nixpkgs.lib;
      pkgs = nixpkgs.legacyPackages.${system};

      packages = with pkgs; [
        (python3.withPackages (py-pkgs:
          with py-pkgs; [
            python-on-whales
          ]))
      ];
    in {
      formatter = pkgs.alejandra;

      packages = rec {
        console = import ./console {
          inherit lib;
          inherit (pkgs) python3Packages;
        };

        default = console;
      };

      devShells.default = pkgs.mkShell {
        DOMAIN_NAME = "cryptic-coders.net";

        inherit packages;
      };
    });
}
