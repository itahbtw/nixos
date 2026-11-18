{ config, ... }:
let
  homeModules = config.flake.modules.homeManager;
in
{
  flake.modules.nixos.homeManagerBase = _: {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "hm-backup";
      overwriteBackup = true;

      users = {
        itah =
          { osConfig, ... }:
          {
            # Home Manager features self-register the same way NixOS features do.
            imports = builtins.attrValues homeModules;

            home = {
              stateVersion = osConfig.system.stateVersion;
              username = "itah";
              homeDirectory = osConfig.users.users.itah.home;
            };

            programs = {
              home-manager = {
                enable = true;
              };
            };
          };
      };
    };
  };
}
