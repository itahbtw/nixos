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
      # Suppress verbose xkbcommon warnings; the X11 keymap is configured
      # explicitly in hosts/nixos/locale.nix.
      sessionVariables.XKB_LOG_LEVEL = "error";

      # System-wide editor defaults; neovim stays in environment.systemPackages
      # (packages.nix) because EDITOR/VISUAL point to it.
      variables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };
    };
  };
}
