_: {
  projectRootFile = "flake.nix";

  programs = {
    alejandra.enable = true;
    deadnix.enable = true;
    statix.enable = true;

    beautysh.enable = true;
    shellcheck.enable = true;

    dockerfmt.enable = true;

    yamlfmt.enable = true;
  };
}
