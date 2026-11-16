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

Automatic upgrades, `nix.gc`, and the periodic `nix.optimise` service are
intentionally disabled. `nix.settings.auto-optimise-store = true`
(`modules/features/nix.nix`) still deduplicates files as they enter the store.
Run when needed:

```bash
nfu                          # cd ~/Nixos && nix flake update
nrs                          # rebuild with the updated lock
sudo nix-collect-garbage -d  # remove old generations
sudo nix-store --optimise    # deduplicate store
ngc                          # nh clean all --optimise
```

## Secrets

Machine secrets are sops-nix + age encrypted and committed under `secrets/`,
decrypted to `/run/secrets/` at activation:

- `wireguard-route64.conf` → `/run/secrets/wireguard-route64.conf`
- `wireguard-vpnbook.conf` → `/run/secrets/wireguard-vpnbook.conf`
- `mariadb-website-password` → `/run/secrets/mariadb-website-password`

The age key is `/var/lib/sops-nix/key.txt`. Back it up — without it `secrets/`
is unrecoverable. `modules/features/secrets.nix` skips sops entirely when no
encrypted file exists, so a fresh clone still evaluates. The OpenCode proxy
config/API key under `/opt` is app-owned runtime state and is intentionally
not managed here.

Edit a secret with:

```bash
sudo SOPS_AGE_KEY_FILE=/var/lib/sops-nix/key.txt \
  sops --input-type binary secrets/<file>
```

## Writable configs

`btop`, `kitty`, `umbriel`, `fastfetch`, and `starship` are activation copies,
not store symlinks. Writes are atomic (temp file + `mv`). Runtime edits to
those files are overwritten on the next `home-manager` activation.

## Rules

- Keep `nixpkgs-unstable` and `linuxPackages_latest`; do not downgrade them.
- Keep the LibreOffice SDPR override gated on `< 26.8.2` (tdf#168910).
- Commit `flake.lock` after a successful `nfu` + `nrs` so input updates are pinned.
- Follow existing formatting; `nixfmt` is authoritative.
