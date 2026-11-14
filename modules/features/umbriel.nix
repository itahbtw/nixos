_: {
  flake.modules.homeManager.umbriel =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      home.activation.umbrielConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        set -eu
        target="${config.xdg.configHome}/umbriel/config.toml"
        mkdir -p "$(dirname "$target")"
        tmp="$target.hm-tmp"
        ${pkgs.coreutils}/bin/cp "${../umbriel/config.toml}" "$tmp"
        ${pkgs.coreutils}/bin/chmod u+w "$tmp"
        ${pkgs.coreutils}/bin/mv -f "$tmp" "$target"
      '';
    };
}
