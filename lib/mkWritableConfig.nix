# Shared helper for Home Manager activations that need an app's config file to
# stay writable. A Nix store symlink cannot be edited at runtime, so these
# activations copy the tracked source into $XDG_CONFIG_HOME on every switch.
# `preCopy` is optional shell code run against the temp file before the atomic
# move (e.g. expanding @HOME@ in umbriel's config).
{
  config,
  pkgs,
  lib,
  name,
  source,
  preCopy ? "",
}:
lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  set -eu
  target="${config.xdg.configHome}/${name}"
  mkdir -p "$(dirname "$target")"
  tmp="$target.hm-tmp"
  ${pkgs.coreutils}/bin/cp "${source}" "$tmp"
  ${pkgs.coreutils}/bin/chmod u+w "$tmp"${lib.optionalString (preCopy != "") "\n${lib.trim preCopy}"}
  ${pkgs.coreutils}/bin/mv -f "$tmp" "$target"
''
