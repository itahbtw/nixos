{
  flake.modules.nixos.firefox =
    { pkgs, ... }:
    {
      programs = {
        firefox = {
          enable = true;

          # Native messenger half of Tridactyl (vim-like Firefox extension).
          nativeMessagingHosts = {
            packages = [
              pkgs.tridactyl-native
            ];
          };

          # Force-install Tridactyl from AMO so the native host has a client.
          policies = {
            ExtensionSettings = {
              "tridactyl@cmcaine.co.uk" = {
                installation_mode = "force_installed";
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/tridactyl/latest.xpi";
              };
            };
          };
        };
      };
    };

  # Firefox 159+ keeps its profile under $XDG_CONFIG_HOME/mozilla/firefox, but
  # Tridactyl's native messenger still discovers profiles via the legacy
  # ~/.mozilla/firefox path. Link the two so `:guiset` and other native
  # commands can find the running profile.
  flake.modules.homeManager.firefox =
    { config, ... }:
    {
      home = {
        file = {
          ".mozilla/firefox" = {
            source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/mozilla/firefox";
          };
        };
      };
    };
}
