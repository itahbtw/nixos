_: {
  flake.modules.nixos.maintenance = _: {
    services = {
      fstrim.enable = true;

      # Monitor NVMe/SATA drive health and warn early.
      smartd.enable = true;

      # Bound the journal; it was already ~850 MiB.
      journald.settings.Journal = {
        SystemMaxUse = "1G";
        RuntimeMaxUse = "256M";
      };
    };

    boot.loader.systemd-boot.configurationLimit = 20;

    # No automatic Nix maintenance: auto-upgrade, nix.gc, and nix.optimise are
    # all disabled. Run them manually when needed:
    #
    #   sudo nix-collect-garbage -d
    #   sudo nix-store --optimise
    #   ngc   # nh clean all --optimise
  };
}
