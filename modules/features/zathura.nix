_: {
  flake.modules.homeManager.zathura =
    { pkgs, ... }:
    {
      home = {
        packages = [
          pkgs.zathura
        ];
      };

      xdg = {
        configFile = {
          "zathura/zathurarc" = {
            text = ''
              set selection-clipboard clipboard
              include ~/.config/zathura/noctaliarc
            '';
          };
        };
      };
    };
}
