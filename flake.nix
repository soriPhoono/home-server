{
  description = "Empty flake with basic devshell";

  inputs = {
    systems.url = "github:nix-systems/x86_64-linux";

    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    agenix.url = "github:ryantm/agenix";
    agenix-shell.url = "github:soriphoono/agenix-shell";

    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.agenix-shell.flakeModules.default
        inputs.treefmt-nix.flakeModule
      ];
      systems = import inputs.systems;
      agenix-shell = {
        secrets = {
          # FOO.file = ./secrets/foo.age;
        };
      };
      perSystem = {
        system,
        pkgs,
        config,
        lib,
        ...
      }: {
        treefmt.programs = {
          alejandra.enable = true;
          deadnix.enable = true;
          statix.enable = true;
        };

        devShells.default = pkgs.mkShell {
          packages = [
            inputs.agenix.packages.${system}.default
          ];
          shellHook = ''
            source ${lib.getExe config.agenix-shell.installationScript}
          '';
        };
      };
    };
}
