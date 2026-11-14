_: {
  flake.modules.homeManager.kitty =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      home.packages = [ pkgs.kitty ];

      home.activation.kittyConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        set -eu
        target="${config.xdg.configHome}/kitty/kitty.conf"
        mkdir -p "$(dirname "$target")"
        tmp="$target.hm-tmp"
        ${pkgs.coreutils}/bin/cp "${../kitty/kitty.conf}" "$tmp"
        ${pkgs.coreutils}/bin/chmod u+w "$tmp"
        ${pkgs.coreutils}/bin/mv -f "$tmp" "$target"
      '';
    };
}
