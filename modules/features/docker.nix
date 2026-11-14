_: {
  flake.modules.nixos.docker = { pkgs, ... }: {
    virtualisation.docker = {
      enable = true;
      enableOnBoot = true;
      # Weekly prune of stopped containers, dangling images, and build cache.
      # Tagged images are kept (`--all` is intentionally not passed).
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };

    # The WARP containers need a TUN device.
    boot.kernelModules = [ "tun" ];

    users.users.itah.extraGroups = [ "docker" ];

    environment.systemPackages = [ pkgs.docker-compose ];
  };
}
