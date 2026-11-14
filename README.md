# itah's NixOS configuration

Dendritic NixOS + Home Manager configuration for the `nixos` host.

## Layout

```text
flake.nix                    flake-parts entry point
flake.lock                   pinned inputs
modules/
├── features/                self-registering features
├── hosts/nixos/             host composition + hardware
├── infrastructure/          flake plumbing, Home Manager base, checks
├── btop/                    raw app config files
├── fastfetch/
├── gtk/
├── kitty/
└── umbriel/
scripts/                     helper scripts
.githooks/pre-commit         format/lint staged files
AGENTS.md                    agent build/test/maintenance notes
```

## How features work

Every `.nix` file under `modules/` is imported by `import-tree`. A feature
registers itself instead of being added to a central list.

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

The host imports every `flake.modules.nixos.*` module, and the Home Manager
base imports every `flake.modules.homeManager.*` module. Adding a new feature
file is enough to enable it.

Raw config files belong in `modules/<app>/` and are referenced from the
matching feature module.

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
`scripts/*.sh` and `modules/noctalia/*.sh`), and evaluates the NixOS toplevel.
`nix develop` provides the same linting tools. `unknown flake output 'modules'`
is benign.

## Updates and maintenance

Automatic upgrades, garbage collection, and store optimisation are disabled (no
auto-upgrade module, no `nix.gc`, no `nix.optimise`). This host tracks
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

Secrets are not stored in the repository:

- WireGuard keys under `/etc` (root-only).
- MariaDB root password in `/root` (root-only).
- opencode API key in `/opt` (root-only).

For reproducibility across hosts, sops-nix or agenix would be the next step.

## Git hooks

`.githooks/pre-commit` formats and lints staged Nix and shell files. Enable it
once per clone:

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
- Auto-importing every module is ideal for this single-host setup. If a second
  host is added with a different feature set, switch the host to explicit
  per-host module lists.
