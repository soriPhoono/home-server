{
  description = "Empty flake with basic devshell";

  inputs = {
    systems.url = "github:nix-systems/x86_64-linux";

    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    agenix.url = "github:ryantm/agenix";
    agenix-shell.url = "github:aciceri/agenix-shell";

    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.agenix-shell.flakeModules.default
      ];
      systems = import inputs.systems;
      agenix-shell = {
        secrets = {
          DOMAIN_NAME.file = ./secrets/domain_name.age;
        };
      };
      perSystem = {
        system,
        pkgs,
        config,
        lib,
        ...
      }: {
        devShells.default = pkgs.mkShell {
          packages = [
            inputs.agenix.packages.${system}.default
          ];
          shellHook = ''
            ${lib.getExe config.agenix-shell.installationScript}
          '';
        };
      };
    };
}
