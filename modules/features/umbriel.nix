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
        # The raw TOML cannot interpolate Nix values, so expand the home path
        # at activation instead of hardcoding /home/<user> in the repo.
        ${pkgs.gnused}/bin/sed -i "s|@HOME@|${config.home.homeDirectory}|g" "$tmp"
        ${pkgs.coreutils}/bin/mv -f "$tmp" "$target"
      '';
    };
}
