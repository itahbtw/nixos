#!/usr/bin/env bash
# Inject the Noctalia-generated palette into the user's starship.toml.
set -euo pipefail

palette_file="${XDG_CACHE_HOME:-$HOME/.cache}/noctalia/starship-palette.toml"
config_file="${STARSHIP_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml}"
marker_begin="# >>> NOCTALIA STARSHIP PALETTE >>>"
marker_end="# <<< NOCTALIA STARSHIP PALETTE <<<"

# Nothing to do until Noctalia has rendered a palette.
[ -f "$palette_file" ] || exit 0

mkdir -p "$(dirname "$config_file")"

tmp_file="$(mktemp "${config_file}.tmp.XXXXXX")"
body_file="$(mktemp "${config_file}.body.XXXXXX")"
trap 'rm -f "$tmp_file" "$body_file"' EXIT

if [ -f "$config_file" ]; then
    # Drop the previous Noctalia block and any palette selection.
    awk -v begin="$marker_begin" -v end="$marker_end" '
        $0 == begin { in_block = 1; next }
        in_block {
            if ($0 == end) in_block = 0
            next
        }
        /^palette[[:space:]]*=/ { next }
        { print }
    ' "$config_file" >"$body_file"
else
    : >"$body_file"
fi

# Re-insert the palette selection after "$schema" when present.
{
    if grep -qE '^"\$schema"' "$body_file"; then
        awk '
            /^"\$schema"/ {
                print
                if (!inserted) {
                    print "palette = \"noctalia\""
                    inserted = 1
                }
                next
            }
            { print }
        ' "$body_file"
    else
        echo 'palette = "noctalia"'
        cat "$body_file"
    fi
    echo ""
    echo "$marker_begin"
    cat "$palette_file"
    echo "$marker_end"
} >"$tmp_file"

# Write through a symlink instead of replacing it, and only on change.
if [ ! -f "$config_file" ] || ! cmp -s "$config_file" "$tmp_file"; then
    cat "$tmp_file" >"$config_file"
fi
