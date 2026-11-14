# AGENTS.md

Guidance for coding agents working in this repository.

## Layout

- `flake.nix`: flake-parts entry point; `modules/` is imported recursively.
- `modules/features/`: one self-registering NixOS/HM module per feature.
- `modules/hosts/nixos/`: host composition and hardware.
- `modules/infrastructure/`: flake plumbing, HM base, checks.
- `modules/<app>/`: raw config files copied into writable XDG paths.
- `scripts/`: helper scripts (shellcheck-clean).

## Validation

Run before reporting a change:

```bash
nix fmt
statix check .
deadnix --fail .
nixfmt --check $(find . -path ./.git -prune -o -name '*.nix' -print)
nix eval --raw .#nixosConfigurations.nixos.config.system.build.toplevel.drvPath
nix flake check --no-build
```

`nix flake check` also runs the `shellcheck` check for `scripts/*.sh` and
`modules/noctalia/*.sh`. `unknown flake output 'modules'` is benign.

## Build / switch

- Dry build: `nrs -n` (alias for `nh os switch ~/Nixos -n`) or
  `nixos-rebuild dry-build --flake ~/Nixos#nixos`.
- Switch: `nrs`; boot-only: `nrb`; temporary test: `nrt`; rollback: `nrr`.
- Do not switch or commit unless the user explicitly asks.

## Maintenance is manual

Automatic upgrades, `nix.gc`, and `nix.optimise` are intentionally disabled.
Run when needed:

```bash
nfu                          # cd ~/Nixos && nix flake update
nrs                          # rebuild with the updated lock
sudo nix-collect-garbage -d  # remove old generations
sudo nix-store --optimise    # deduplicate store
ngc                          # nh clean all --optimise
```

## Secrets

Not stored in the repo:

- WireGuard keys under `/etc` (root-only).
- MariaDB root password in `/root` (root-only).
- opencode API key in `/opt` (root-only).

## Writable configs

`btop`, `kitty`, `umbriel`, `fastfetch`, and `starship` are activation copies,
not store symlinks. Writes are atomic (temp file + `mv`). Runtime edits to
those files are overwritten on the next `home-manager` activation.

## Rules

- Keep `nixpkgs-unstable` and `linuxPackages_latest`; do not downgrade them.
- Keep the LibreOffice SDPR override gated on `< 26.8.2` (tdf#168910).
- Do not commit `flake.lock` changes unless asked.
- Follow existing formatting; `nixfmt` is authoritative.
