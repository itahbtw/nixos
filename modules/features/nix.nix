_: {
  flake.modules.nixos.nix = _: {
    nixpkgs.config.allowUnfree = true;

    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
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
