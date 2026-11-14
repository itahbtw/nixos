_: {
  flake.modules.homeManager.fastfetch =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      home.packages = [ pkgs.fastfetch ];

      # Keep config.jsonc a real, writable file (not a store symlink) so the
      # Noctalia fastfetch template's apply.sh can merge theme colors into it.
      home.activation.fastfetchConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        set -eu
        target="${config.xdg.configHome}/fastfetch/config.jsonc"
        mkdir -p "$(dirname "$target")"
        # Replace any pre-existing read-only store symlink with a real file.
        if [ -L "$target" ]; then
          tmp_link="$(${pkgs.coreutils}/bin/mktemp)"
          ${pkgs.coreutils}/bin/cp -L "$target" "$tmp_link" 2>/dev/null || true
          ${pkgs.coreutils}/bin/rm -f "$target"
          if [ -s "$tmp_link" ]; then
            ${pkgs.coreutils}/bin/mv "$tmp_link" "$target"
          else
            ${pkgs.coreutils}/bin/rm -f "$tmp_link"
          fi
        fi
        store_config="${../fastfetch/config.jsonc}"
        tmp="$(${pkgs.coreutils}/bin/mktemp "$target".tmp.XXXXXX)"
        if [ ! -f "$target" ]; then
          ${pkgs.coreutils}/bin/cp "$store_config" "$tmp"
        elif ${pkgs.jq}/bin/jq -e . "$store_config" >/dev/null 2>&1 && ${pkgs.jq}/bin/jq -e . "$target" >/dev/null 2>&1; then
          ${pkgs.jq}/bin/jq -s '.[0] * {logo: (.[1].logo // .[0].logo), display: (.[1].display // .[0].display)}' "$store_config" "$target" > "$tmp"
        else
          ${pkgs.coreutils}/bin/cp "$store_config" "$tmp"
        fi
        ${pkgs.coreutils}/bin/chmod u+w "$tmp"
        ${pkgs.coreutils}/bin/mv -f "$tmp" "$target"
      '';
    };
}
