_: {
  flake.modules.homeManager.kitty =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      home.packages = [
        pkgs.kitty
      ];

      home.activation.kittyConfig = import ../../lib/mkWritableConfig.nix {
        inherit config pkgs lib;
        name = "kitty/kitty.conf";
        source = ../kitty/kitty.conf;
      };
    };
}
