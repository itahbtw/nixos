_: {
  flake.modules.homeManager.btop =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      home.packages = [ pkgs.btop ];

      home.activation.btopConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        set -eu
        target="${config.xdg.configHome}/btop/btop.conf"
        mkdir -p "$(dirname "$target")"
        tmp="$target.hm-tmp"
        ${pkgs.coreutils}/bin/cp "${../btop/btop.conf}" "$tmp"
        ${pkgs.coreutils}/bin/chmod u+w "$tmp"
        ${pkgs.coreutils}/bin/mv -f "$tmp" "$target"
      '';
    };
}
