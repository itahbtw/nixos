_: {
  flake.modules.homeManager.umbriel =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      home = {
        activation = {
          umbrielConfig = import ../../lib/mkWritableConfig.nix {
            inherit config pkgs lib;
            name = "umbriel/config.toml";
            source = ../umbriel/config.toml;
            preCopy = ''
              # The raw TOML cannot interpolate Nix values, so expand the home path
              # at activation instead of hardcoding /home/<user> in the repo.
              ${pkgs.gnused}/bin/sed -i "s|@HOME@|${config.home.homeDirectory}|g" "$tmp"
            '';
          };
        };
      };
    };
}
