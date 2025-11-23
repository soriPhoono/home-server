{
  description = "Empty flake with basic devshell";

  inputs = {
    systems.url = "github:nix-systems/x86_64-linux";

    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    agenix.url = "github:ryantm/agenix";
    agenix-shell.url = "github:aciceri/agenix-shell";

    treefmt-nix.url = "github:numtide/treefmt-nix";

    git-hooks-nix.url = "github:cachix/git-hooks.nix";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = with inputs; [
        agenix-shell.flakeModules.default
        treefmt-nix.flakeModule
        git-hooks-nix.flakeModule
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
        devShells.default = pkgs.mkShell {
          packages = [
            inputs.agenix.packages.${system}.default
          ];
          shellHook = ''
            source ${lib.getExe config.agenix-shell.installationScript}

            ${config.pre-commit.shellHook}
          '';
        };

        treefmt.programs = {
          alejandra.enable = true;
          deadnix.enable = true;
          statix.enable = true;
        };

        pre-commit = {
          check.enable = true;
          settings.hooks = {
            alejandra.enable = true;
            deadnix.enable = true;
            statix.enable = true;

            treefmt.enable = true;
          };
        };
      };
    };
}
