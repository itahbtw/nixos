_: {
  flake.modules.homeManager.yazi = { pkgs, ... }: {
    programs.yazi = {
      enable = true;
      extraPackages = with pkgs; [
        gnutar
        zip
        unzip
        p7zip
        unrar
        libarchive # bsdtar
        gzip
        xz
        bzip2
        zstd
        lz4
      ];
      plugins = {
        # Upstream `main` (80e5268) — 0.6 tag still uses removed `fs.unique_name`
        # and old `u.parent` API; breaks on Yazi 26.x (see KKV9/compress.yazi#37/#39).
        compress = pkgs.stdenvNoCC.mkDerivation {
          pname = "compress.yazi";
          version = "0.6-main-80e5268";
          src = pkgs.fetchurl {
            url = "https://github.com/KKV9/compress.yazi/archive/80e5268ec74c7ac17d4d739e13a9958cba4c70d3.tar.gz";
            hash = "sha256-ZdVXEhJpWdwXzBwFSgOse+uMe27n74xocky/UYfYTMY=";
          };
          installPhase = ''
            mkdir -p $out
            tar -xzf $src -C $out --strip-components=1
          '';
        };
      };
      keymap = {
        mgr.prepend_keymap = [
          {
            on = [
              "c"
              "a"
              "a"
            ];
            run = "plugin compress";
            desc = "Archive selected files";
          }
          {
            on = [
              "c"
              "a"
              "p"
            ];
            run = "plugin compress -p";
            desc = "Archive (password)";
          }
          {
            on = [
              "c"
              "a"
              "h"
            ];
            run = "plugin compress -ph";
            desc = "Archive (password+header)";
          }
          {
            on = [
              "c"
              "a"
              "l"
            ];
            run = "plugin compress -l";
            desc = "Archive (compression level)";
          }
          {
            on = [
              "c"
              "a"
              "u"
            ];
            run = "plugin compress -phl";
            desc = "Archive (all options)";
          }
        ];
      };
    };
  };
}
