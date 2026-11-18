_: {
  flake.modules.nixos.screen-mirror =
    { pkgs, ... }:
    {
      environment = {
        systemPackages = with pkgs; [
          wl-mirror
          (writeShellApplication {
            name = "screen-mirror-toggle";
            runtimeInputs = [
              wl-mirror
              coreutils
              procps
              libnotify
            ];
            text = ''
              set -eu

              source_output="''${1:-eDP-1}"
              target_output="''${2:-HDMI-A-1}"
              pidfile="''${XDG_RUNTIME_DIR:-/tmp}/screen-mirror.pid"

              if [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
                kill "$(cat "$pidfile")" 2>/dev/null || true
                rm -f "$pidfile"
                pkill -f "wl-mirror.*$source_output" 2>/dev/null || true
                notify-send "Screen mirror" \
                  "Stopped ($source_output → $target_output)" 2>/dev/null || true
                exit 0
              fi

              rm -f "$pidfile"
              pkill -f "wl-mirror.*$source_output" 2>/dev/null || true

              wl-mirror "$source_output" >/dev/null 2>&1 &
              echo $! > "$pidfile"

              notify-send "Screen mirror" \
                "Mirroring $source_output → $target_output" 2>/dev/null || true
            '';
          })
        ];
      };
    };
}
