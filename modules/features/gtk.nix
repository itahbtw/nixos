_: {
  flake.modules.homeManager.gtk =
    { pkgs, ... }:
    {
      home = {
        packages = [
          pkgs.adw-gtk3
        ];
      };

      xdg = {
        configFile = {
          "gtk-3.0/gtk.css" = {
            source = ../gtk/gtk-3.0/gtk.css;
          };

          "gtk-4.0/gtk.css" = {
            source = ../gtk/gtk-4.0/gtk.css;
          };
        };
      };
    };
}
