# Encrypted secrets

Files here are sops-encrypted (binary format) with the age key at
`/var/lib/sops-nix/key.txt` and are decrypted to `/run/secrets/` at activation.

| File | Consumer |
| --- | --- |
| `wireguard-route64.conf` | `services.route64Tunnel` |
| `wireguard-vpnbook.conf` | `networking.wg-quick.interfaces.vpnbook` |
| `mariadb-website-password` | `mariadb-website-password.service` |

Bootstrap (once, root):

```bash
sudo ./scripts/migrate-secrets-to-sops.sh
git add .sops.yaml secrets && nrs
```

Back up `/var/lib/sops-nix/key.txt`: without it these files are unrecoverable.
Rotate/edit with:

```bash
sudo SOPS_AGE_KEY_FILE=/var/lib/sops-nix/key.txt \
  sops --input-type binary secrets/wireguard-route64.conf
```

The OpenCode proxy config in `/opt` is app-owned runtime state and is
intentionally not managed here.
