_: {
  flake.modules.nixos.hostFact-nixos-boot = { pkgs, ... }: {
    boot = {
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
        # Do not leave the boot menu editable without authentication.
        systemd-boot.editor = false;
      };
      kernelPackages = pkgs.linuxPackages_latest;
      tmp.cleanOnBoot = true;

      # Hardening. Several of these are already kernel defaults on this machine;
      # setting them explicitly keeps them stable across kernel bumps. Avoid
      # rp_filter here because the WARP/Docker and route64 setups use non-local
      # source addresses.
      kernel.sysctl = {
        # Kernel-pointer / dmesg information leaks (recon hardening).
        "kernel.kptr_restrict" = 2;
        "kernel.dmesg_restrict" = 1;

        # Restrict ptrace to descendants; blocks same-user memory scraping.
        "kernel.yama.ptrace_scope" = 1;

        # Block classic /tmp symlink, hardlink, and FIFO attacks.
        "fs.protected_symlinks" = 1;
        "fs.protected_hardlinks" = 1;
        "fs.protected_fifos" = 1;

        # Don't let an unprivileged ioctl auto-load a TTY line-discipline module.
        "dev.tty.ldisc_autoload" = 0;

        # SYN cookies engage only under a SYN flood, so no cost in normal use.
        "net.ipv4.tcp_syncookies" = 1;

        # Ignore ICMP redirects and source-routed packets (route injection).
        "net.ipv4.conf.all.accept_redirects" = 0;
        "net.ipv4.conf.default.accept_redirects" = 0;
        "net.ipv4.conf.all.accept_source_route" = 0;
        "net.ipv4.conf.default.accept_source_route" = 0;
      };
    };
  };
}
