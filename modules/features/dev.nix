_: {
  flake.modules.nixos.dev = { pkgs, ... }: {
    environment = {
      systemPackages = with pkgs; [
        # C / C++
        gcc
        clang
        clang-tools
        cmake
        gnumake
        gdb

        # Web (HTML, CSS, JS, TS)
        nodejs
        typescript
        typescript-language-server
        vscode-langservers-extracted
        prettier
        eslint

        # PHP
        php
        php85Packages.composer
        php85Packages.php-cs-fixer
        phpactor

        # Java: JDK 21 is the default for Gradle/Kotlin/Android; JDK 25 is for jdtls.
        jdk
        jdk25
        gradle

        # Maven and jdt-language-server are omitted: Gradle + Mason's jdtls suffice.

        # Android
        android-tools
        kotlin

        # Lua
        lua
        lua-language-server
        stylua

        # Nix
        nixfmt
        nixd
        statix
        deadnix

        # Rust
        rustc
        cargo
        rustfmt
        clippy
        rust-analyzer
      ];
      variables = {
        JDTLS_JAVA_HOME = "${pkgs.jdk25}";
        JDK21_HOME = "${pkgs.jdk}";
      };
    };

    programs.nix-ld.enable = true;

    # FHS libraries for the Android SDK emulator (X11/GL/audio/QEMU).
    programs.nix-ld.libraries = with pkgs; [
      libx11
      libxext
      libxrender
      libxtst
      libxi
      libxfixes
      libxcursor
      libxrandr
      libxkbfile
      libxdamage
      libxcomposite
      libxinerama
      libxscrnsaver
      libxmu
      libxpm
      libsm
      libice
      libxcb
      xcbutil
      xcbutilimage
      xcbutilkeysyms
      xcbutilrenderutil
      xcbutilwm
      xcbutilcursor
      xcbutilerrors
      libepoxy
      libpulseaudio
      libpng
      alsa-lib
      libxkbcommon
      libglvnd
      mesa
      libdrm
      libxshmfence
      nspr
      nss
      libusb1
      dbus
      glib
      zlib
      expat
      libcap
      libbsd
      libmd
      libelf
      libaio
      liburing
      numactl
      libseccomp
      libslirp
    ];
  };
}
