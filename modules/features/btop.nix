_: {
  flake.modules.homeManager.btop =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      home = {
        packages = [
          pkgs.btop
        ];

        activation = {
          btopConfig = import ../../lib/mkWritableConfig.nix {
            inherit config pkgs lib;
            name = "btop/btop.conf";
            source = ../btop/btop.conf;
          };
        };
      };
    };
}
