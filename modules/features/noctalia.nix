_: {
  flake.modules.homeManager.noctalia =
    { pkgs, ... }:
    {
      programs.noctalia = {
        enable = true;
        package = pkgs.noctalia;

        # The systemd service is owned by the NixOS module (desktop.nix); Home
        # Manager only generates config.toml from `settings` below.
        checkConfig = true;

        # Settings live in a dedicated file so this stays a thin wrapper. The
        # `_` prefix keeps import-tree from treating it as a flake-parts module.
        settings = import ../noctalia/_settings.nix;
      };
    };
}
