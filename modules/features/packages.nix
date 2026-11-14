_: {
  flake.modules.nixos.packages = { pkgs, lib, ... }: {
    # Zotero ships its own Firefox ESR build, which nixpkgs flags as insecure.
    # The pin tracks Zotero's bundled version; update it when eval complains.
    nixpkgs.config.permittedInsecurePackages = [
      "firefox-esr-140-bin-unwrapped-140.17.0esr"
    ];

    environment.systemPackages = with pkgs; [
      # Nix / system management
      git
      nh
      nvd
      nix-tree

      # Shell and terminal helpers
      tealdeer
      duf
      ncdu
      wget
      wl-clipboard
      xdg-user-dirs
      wev

      # Development tools
      neovim
      lazygit
      gh
      python3
      jq
      opencode

      # CLI utilities
      ffmpeg
      p7zip
      zip
      unzip
      poppler-utils
      fd
      ripgrep
      eza
      bat
      dust
      procs
      imagemagick
      resvg
      mariadb
      mycli

      # GUI applications
      proton-authenticator
      proton-vpn
      # SDPR causes tdf#168910 (white lines across images while scrolling) and
      # tdf#164476 (invisible sidebar controls). 26.8.2 fixes the former, so
      # only disable it on affected releases; newer builds run the normal path.
      (
        if lib.versionOlder libreoffice.version "26.8.2" then
          libreoffice.override {
            extraMakeWrapperArgs = [
              "--set"
              "DISABLE_SYSTEM_DEPENDENT_PRIMITIVE_RENDERER"
              "1"
            ];
          }
        else
          libreoffice
      )
      vscode
      zotero
      imv
      mpv
    ];

    # OBS: use the NixOS module so plugins (wlrobs for wlroots capture) are
    # wrapped into the package. Screen capture on Wayland goes through the
    # PipeWire/portal path; wlrobs is a direct wlroots fallback. Webcam
    # capture needs /dev/video* access, handled by the `video` group.
    programs.obs-studio = {
      enable = true;
      plugins = [ pkgs.obs-studio-plugins.wlrobs ];
    };
  };
}
