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
        openssl
      ];
    in {
      formatter = pkgs.alejandra;

      packages = {
        console = import ./. {
          inherit lib;
          inherit (pkgs) python3Packages;
        };
      };

      devShells.default = pkgs.mkShell {
        DOMAIN_NAME = "localhost";

        inherit packages;
      };
    });
}
