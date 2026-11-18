_: {
  flake.modules.nixos.hostFact-nixos-brightness =
    { pkgs, ... }:
    {
      environment = {
        systemPackages = [
          (pkgs.writeShellScriptBin "brightness-adaptive" ''
            set -euo pipefail
            dir="''${1:-up}"

            dev=""
            for d in /sys/class/backlight/*; do
              if [ -r "$d/brightness" ] && [ -r "$d/max_brightness" ]; then
                dev="$d"
                break
              fi
            done

            if [ -z "$dev" ]; then
              if [ "$dir" = "down" ]; then
                noctalia msg brightness-down
              else
                noctalia msg brightness-up
              fi
              exit 0
            fi

            cur="$(cat "$dev/brightness")"
            max="$(cat "$dev/max_brightness")"

            if [ "$max" -le 0 ]; then
              step=5
            else
              pct=$(( cur * 100 / max ))
              if [ "$dir" = "down" ]; then
                if [ "$pct" -le 5 ]; then
                  step=1
                else
                  prev=$(( (pct / 5) * 5 ))
                  if [ "$prev" -eq "$pct" ]; then
                    prev=$(( pct - 5 ))
                  fi
                  if [ "$prev" -lt 0 ]; then
                    prev=0
                  fi
                  step=$(( pct - prev ))
                  if [ "$step" -le 0 ]; then
                    step=5
                  fi
                fi
              else
                if [ "$pct" -lt 5 ]; then
                  step=1
                else
                  nxt=$(( (pct / 5 + 1) * 5 ))
                  if [ "$nxt" -gt 100 ]; then
                    nxt=100
                  fi
                  step=$(( nxt - pct ))
                  if [ "$step" -le 0 ]; then
                    step=5
                  fi
                fi
              fi
            fi

            if [ "$dir" = "down" ]; then
              noctalia msg brightness-down "" "$step"
            else
              noctalia msg brightness-up "" "$step"
            fi
          '')
        ];
      };
    };
}
