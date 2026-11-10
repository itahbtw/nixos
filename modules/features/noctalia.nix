_: {
  flake.modules.homeManager.noctalia = { pkgs, ... }: {
    programs.noctalia = {
      enable = true;
      package = pkgs.noctalia;
      systemd.enable = false;
      checkConfig = true;
      settings = {
        bar.default = {
          position = "top";
          thickness = 28;
          margin_ends = 0;
          panel_overlap = 1;
          radius = 0;
          capsule = false;
          font_family = "JetBrainsMono Nerd Font";
          font_weight = 700;
          font_scale = 1.1;
          background_opacity = 1.0;
          compositor_blur = true;
          shadow = false;
          contact_shadow = false;
          start = [
            "workspaces"
            "sep"
            "umbriel"
            "sep"
            "active_window"
          ];
          center = [
            "clock"
            "sep"
            "weather"
          ];
          end = [
            "media"
            "sep"
            "ram"
            "sep"
            "cpu"
            "sep"
            "temp"
            "sep"
            "network"
            "sep"
            "volume"
            "sep"
            "brightness"
            "sep"
            "bat"
          ];
          widget_spacing = 6;
          padding = 8;
        };

        widget = {
          workspaces = {
            type = "workspaces";
            style = "regular";
            show_labels = true;
            label_source = "id";
            change_color_on_hover = true;
          };
          umbriel = {
            type = "noctalia/umbriel-companion:bar";
          };
          active_window = {
            type = "active_window";
          };
          sep = {
            type = "text";
            color = "#585b70";
            text = "│";
          };
          media = {
            type = "media";
            color = "#cba6f7";
            hide_when_no_media = false;
          };
          ram = {
            type = "sysmon";
            stat = "ram_used";
            highlight_color = "error";
            visualization = "none";
            show_glyph = true;
            show_value = true;
            label_show_units = true;
          };
          cpu = {
            type = "sysmon";
            stat = "cpu_usage";
            highlight_color = "error";
            visualization = "none";
            show_glyph = true;
            show_value = true;
            label_show_units = true;
          };
          temp = {
            type = "sysmon";
            stat = "cpu_temp";
            highlight_color = "error";
            visualization = "none";
            show_glyph = true;
            show_value = true;
            label_show_units = true;
          };
          clock = {
            type = "clock";
            format = "󰃭 {:%a, %b %d - %H:%M}";
          };
          bat = {
            type = "battery";
            display_mode = "glyph";
            show_label = true;
            label_content = "percent";
          };
          network = {
            type = "network";
          };
          volume = {
            type = "volume";
          };
          brightness = {
            type = "brightness";
          };
          weather = {
            type = "weather";
          };
        };

        plugins.enabled = [
          "noctalia/wallhaven"
          "noctalia/umbriel-companion"
          "avivbintangaringga/nix-monitor"
        ];

        shell = {
          font_family = "JetBrainsMono Nerd Font";
          popup_shadows = false;
        };
        shell.panel.shadow = false;
        dock.shadow = false;
        dock.icon_shadow = false;

        theme = {
          mode = "dark";
          source = "builtin";
          builtin = "Gruvbox";

          templates = {
            enable_builtin_templates = true;
            enable_community_templates = true;
            builtin_ids = [
              "btop"
              "gtk3"
              "gtk4"
              "kitty"
              "umbriel"
            ];
            community_ids = [
              "opencode"
              "lazyvim"
              "libreoffice"
              "neovim"
              "vscode"
              "fastfetch"
              "obs"
              "zathura"
              "bat"
              "fzf"
              "lazygit"
              "yazi"
            ];

            user.starship = {
              input_path = "${../noctalia/starship-palette.toml}";
              output_path = "$XDG_CACHE_HOME/noctalia/starship-palette.toml";
              post_hook = "bash ${../noctalia/starship-palette.sh}";
            };
          };
        };
      };
    };
  };
}
