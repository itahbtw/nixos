{ inputs, ... }:
{
  flake.modules.nixos.helium = { ... }: {
    imports = [ inputs.helium.nixosModules.default ];

    programs.helium = {
      enable = true;

      # Umbriel is Wayland (wlroots) — force native Wayland so popups/menus
      # render as xdg_popups instead of XWayland, and keep client-side
      # decorations in sync with prefer_no_csd.
      flags = [
        "--ozone-platform-hint=auto"
        "--enable-features=WaylandWindowDecorations"
        "--enable-wayland-ime=true"
      ];
    };
  };
}
