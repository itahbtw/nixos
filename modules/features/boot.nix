_: {
  flake.modules.nixos.boot = { pkgs, ... }: {
    boot = {
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
        # Do not leave the boot menu editable without authentication.
        systemd-boot.editor = false;
      };
      kernelPackages = pkgs.linuxPackages_latest;
      tmp.cleanOnBoot = true;

      # Lightweight hardening; avoid rp_filter here because the WARP/Docker and
      # route64 setups use non-local source addresses.
      kernel.sysctl = {
        "kernel.kptr_restrict" = 2;
        "kernel.dmesg_restrict" = 1;
        "net.ipv4.tcp_syncookies" = 1;
      };
    };
  };
}
