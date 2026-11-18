_: {
  flake.modules.nixos.cursor =
    { pkgs, ... }:
    {
      environment = {
        systemPackages = [
          pkgs.bibata-cursors
        ];
      };
    };

  flake.modules.homeManager.cursor =
    { pkgs, ... }:
    {
      home = {
        pointerCursor = {
          enable = true;
          name = "Bibata-Modern-Ice";
          package = pkgs.bibata-cursors;
          size = 24;

          gtk = {
            enable = true;
          };

          x11 = {
            enable = true;
          };
        };
      };
    };
}
