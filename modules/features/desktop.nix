_: {
  flake.modules.nixos.desktop =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      fonts = {
        packages = [
          pkgs.nerd-fonts.jetbrains-mono
          pkgs.noto-fonts-color-emoji
          pkgs.corefonts
          pkgs.vista-fonts
        ];
      };

      # Noctalia launches apps through `systemd-run --user`, which resolves the
      # executable using the service's PATH. The upstream module disables the
      # default path, and the minimal one lacks the system/user profiles, so
      # launcher entries fail with "No such file or directory" (and template
      # hooks cannot find bash). Give it the same profiles as a login shell.
      systemd = {
        user = {
          services = {
            noctalia = {
              path = [
                "/run/wrappers"
                "/run/current-system/sw"
                "/etc/profiles/per-user/${config.users.users.itah.name}"
                "/nix/var/nix/profiles/default"
              ];
            };
          };
        };
      };

      programs = {
        umbriel = {
          enable = true;
        };

        # This module owns the Noctalia systemd service and its recommended
        # integrations; the Home Manager module only generates config.toml.
        noctalia = {
          enable = true;

          systemd = {
            enable = true;
            target = "graphical-session.target";
          };

          recommendedServices = {
            enable = true;
          };
        };
      };

      # Umbriel's portal only implements ScreenCast + Screenshot. GTK backend
      # removed (no portal Settings/FileChooser); apps needing those fall back to
      # their own dialogs / gsettings. Umbriel stays preferred for capture.
      xdg = {
        portal = {
          extraPortals = lib.mkForce [
            pkgs.xdg-desktop-portal-umbriel
            pkgs.xdg-desktop-portal-gtk
          ];

          config = {
            common = {
              default = [
                "umbriel"
              ];
              "org.freedesktop.impl.portal.ScreenCast" = [
                "umbriel"
              ];
              "org.freedesktop.impl.portal.Screenshot" = [
                "umbriel"
              ];
              # PipeWire camera capture (OBS "Video Capture Device (PipeWire)")
              # needs a backend that implements the Camera portal; Umbriel does not.
              "org.freedesktop.impl.portal.Camera" = [
                "gtk"
              ];
              "org.freedesktop.impl.portal.Secret" = [
                "gnome-keyring"
              ];
            };
          };
        };
      };

      services = {
        displayManager = {
          noctalia-greeter = {
            enable = true;
            settings = {
              cursor = {
                theme = "Bibata-Modern-Ice";
                size = 24;
              };
              keyboard = {
                layout = "us";
              };
            };
          };
        };

        pipewire = {
          enable = true;

          alsa = {
            enable = true;
          };

          pulse = {
            enable = true;
          };

          # PipeWire's X11 bell module connects to XWayland and crashes the
          # whole daemon (SIGSEGV in libpipewire-module-x11-bell) whenever
          # that X11 connection drops, which under Umbriel/Wayland happens
          # regularly and takes audio down with it. Disable it; the compositor
          # does not need PipeWire to play X11 bells.
          extraConfig = {
            pipewire = {
              "99-disable-x11-bell" = {
                context = {
                  properties = {
                    "module.x11.bell" = false;
                  };
                };
              };
            };
          };
        };

        speechd = {
          enable = false;
        };
      };

      # PipeWire (and other real-time audio) benefit from rtkit for scheduling;
      # without it PipeWire logs RTKit errors and runs degraded.
      security = {
        rtkit = {
          enable = true;
        };
      };

      # Enable the Bluetooth adapter so Noctalia's Bluetooth panel works.
      hardware = {
        bluetooth = {
          enable = true;
        };

        # The NPU module enables this implicitly; keep it explicit so disabling
        # the NPU cannot silently remove the GPU stack. Intel Arc (Arrow Lake)
        # needs iHD for VA-API decode and oneVPL for QSV encode (OBS/ffmpeg).
        graphics = {
          enable = true;
          extraPackages = with pkgs; [
            intel-media-driver
            vpl-gpu-rt
          ];
        };
      };

      # Compressed in-RAM swap for better responsiveness on the laptop.
      zramSwap = {
        enable = true;
      };

      # zram (priority 5) is used before the disk swap partition (-1). Bias the
      # kernel toward the fast compressed device instead of the SSD.
      boot = {
        kernel = {
          sysctl = {
            "vm.swappiness" = 100;
          };
        };
      };
    };
}
