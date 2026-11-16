# itah's NixOS configuration

Dendritic NixOS + Home Manager configuration for the `nixos` host.

## Layout

```text
flake.nix                    flake-parts entry point
flake.lock                   pinned inputs
ruff.toml                    Python lint/format policy
modules/
├── features/                self-registering features
├── hosts/nixos/             host bundle + machine facts
├── infrastructure/          flake plumbing, Home Manager base, checks
├── btop/                    raw app config files
├── fastfetch/
├── gtk/
├── kitty/
├── mariadb/                 init.sql bootstrap (no secrets)
├── noctalia/                starship palette template + hook
└── umbriel/
scripts/                     helper scripts (route64, opencode-proxy, secrets)
secrets/                     sops-encrypted secrets (created by migration)
.githooks/pre-commit         format/lint staged Nix, shell, Python
AGENTS.md                    agent build/test/maintenance notes
```

## How features work

Only flake-parts modules live under `modules/`. `import-tree` imports every
`.nix` file there, except paths containing `/_` and `modules/lib/` (reserved for
private helper libraries). A feature registers itself instead of being added to
a central list.

NixOS feature:

```nix
_: {
  flake.modules.nixos.foo = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.foo ];
  };
}
```

Home Manager feature:

```nix
_: {
  flake.modules.homeManager.foo = { pkgs, ... }: {
    home.packages = [ pkgs.foo ];
  };
}
```

Hosts are bundles as well:

```nix
# modules/hosts/nixos/default.nix
{ config, ... }: {
  flake.modules.nixos.host-nixos = {
    imports = [ config.flake.modules.nixos.hostFact-nixos-hardware /* ... */ ];
  };
}
```

`modules/infrastructure/nixos.nix` turns every `flake.modules.nixos.host-<name>`
bundle into `nixosConfigurations.<name>` and composes all non-host modules into
it automatically. Machine facts (disks, hostname, timezone, user) are registered
as `hostFact-<name>-*` and only pulled in by that host's bundle, so adding
`modules/hosts/<name>/default.nix` is enough to support a second host.

Host-agnostic features are exported as `flake.nixosModules` /
`flake.homeManagerModules` (host facts excluded). Attribute keys sort
alphabetically; never rely on file order for precedence — use `imports` or
`lib.mkBefore`/`mkAfter`.

Raw config files belong in `modules/<app>/` and are referenced from the
matching feature module. Private helper code goes in root `lib/` or under any
`_`-prefixed path, which `import-tree` ignores.

## Common commands

| Command | Purpose |
| --- | --- |
| `nrs` | `nh os switch ~/Nixos` |
| `nrb` | `nh os boot ~/Nixos` |
| `nrt` | `nh os test ~/Nixos` |
| `nru` | `nh os switch ~/Nixos --update` |
| `nrr` | `nh os rollback` |
| `nfu` | `cd ~/Nixos && nix flake update` |
| `nrd` | dry-build with `nh os switch ~/Nixos -n` |
| `ndiff` | diff current system against `./result` |
| `ngc` | `nh clean all --optimise` |

The aliases come from `modules/features/shell.nix` and work in both bash and
fish.

## Validation

```bash
nix flake check
nixos-rebuild dry-build --flake ~/Nixos#nixos
nix fmt
nix develop
```

`nix flake check` runs `statix`, `deadnix`, `nixfmt`, `shellcheck` (for
`scripts/*.sh` and `modules/noctalia/*.sh`), `ruff` (for `scripts/*.py`), and
evaluates the NixOS toplevel.
`nix develop` provides the same linting tools. The `unknown flake output
'modules'` and `'homeManagerModules'` warnings are benign (dendritic/export
outputs).

## Updates and maintenance

Automatic upgrades, garbage collection, and the periodic `nix.optimise` service
are disabled (no auto-upgrade module, no `nix.gc`, no `nix.optimise`). Files are
still deduplicated as they enter the store via
`nix.settings.auto-optimise-store = true` in `modules/features/nix.nix`; set it
to `false` there if you want optimisation to be fully manual. This host tracks
`nixpkgs-unstable` and `linuxPackages_latest`, so updates are manual:

```bash
nfu                          # cd ~/Nixos && nix flake update
nrs                          # rebuild/switch with the updated lock
sudo nix-collect-garbage -d  # remove old generations
sudo nix-store --optimise    # deduplicate the store
ngc                          # nh clean all --optimise
```

Review `ndiff` after a rebuild and use `nrr` to roll back if needed.

## Secrets

Machine secrets are encrypted with sops-nix + age and committed under
`secrets/`; they are decrypted to `/run/secrets/` at activation:

- WireGuard: `/run/secrets/wireguard-route64.conf`, `/run/secrets/wireguard-vpnbook.conf`
- MariaDB: `/run/secrets/mariadb-website-password`

Bootstrap once as root:

```bash
sudo ./scripts/migrate-secrets-to-sops.sh
git add .sops.yaml secrets && nrs
```

The script generates `/var/lib/sops-nix/key.txt`. **Back that key up**; without
it `secrets/` is unrecoverable. Edit a secret with:

```bash
sudo SOPS_AGE_KEY_FILE=/var/lib/sops-nix/key.txt \
  sops --input-type binary secrets/<file>
```

The OpenCode proxy config in `/opt` is app-owned runtime state (the update
script merges local overrides into it), so it is intentionally not managed by
sops.

## Git hooks

`.githooks/pre-commit` formats and lints staged Nix, shell, and Python files.
Enable it once per clone:

```bash
git config core.hooksPath .githooks
```

## Notes

- `features/nvim.nix` bootstraps LazyVim via home-manager. It is
  intentionally mutable so you can edit the Neovim config normally.
- `kitty`, `btop`, `fastfetch`, and `umbriel` use activation copies so their
  configs stay writable. Writes are atomic (temp file + `mv`), and runtime
  edits are overwritten on the next activation. Noctalia also writes theme
  files at runtime.
- Host bundles (`host-<name>`) import that machine's `hostFact-<name>-*` modules,
  while all other modules are composed into every host. If a host should not
  have a common feature, give that feature an explicit `enable` option instead
  of maintaining a separate module list. Common features that reference
  `users.users.itah` assume that user exists on every host.
