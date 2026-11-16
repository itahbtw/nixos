_: {
  flake.modules.nixos.nix = _: {
    nixpkgs.config.allowUnfree = true;

    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # Deduplicate files as they enter the store. This is distinct from the
      # periodic nix.optimise service (intentionally off, see maintenance.nix)
      # and from nix.gc; leave it on unless you want fully manual optimisation.
      auto-optimise-store = true;
    };

    # The system tracks nixpkgs-unstable on purpose; updates are manual.
    environment = {
      sessionVariables.XKB_LOG_LEVEL = "error";
      variables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };
    };
  };
}
