#!/usr/bin/env bash
# Encrypt this machine's root-only secrets into secrets/ with sops + age.
# Run once as root, then commit secrets/ and .sops.yaml and rebuild.
set -euo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "Run with sudo: sudo $0" >&2
  exit 1
fi

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
key=/var/lib/sops-nix/key.txt
secrets_dir="$repo/secrets"
declare -A sources=(
  [wireguard-route64.conf]=/etc/wireguard/route64.conf
  [wireguard-vpnbook.conf]=/etc/wireguard/vpnbook.conf
  [mariadb-website-password]=/root/mariadb-website-password
)

if ! command -v sops >/dev/null || ! command -v age-keygen >/dev/null; then
  echo "sops/age not found; re-running inside a nix shell..." >&2
  exec nix shell nixpkgs#sops nixpkgs#age -c bash "$0" "$@"
fi

install -d -m 0700 /var/lib/sops-nix
if [[ ! -s $key ]]; then
  age-keygen -o "$key"
  chmod 0600 "$key"
  echo "Generated age key: $key"
  echo "BACK THIS FILE UP; without it secrets/ cannot be decrypted."
else
  echo "Using existing age key: $key"
fi

recipient=$(age-keygen -y "$key")

if [[ -e $repo/.sops.yaml ]]; then
  cp -a "$repo/.sops.yaml" "$repo/.sops.yaml.bak"
  echo "Backed up existing .sops.yaml to .sops.yaml.bak" >&2
fi
cat > "$repo/.sops.yaml" <<EOF
keys:
  - &nixos $recipient
creation_rules:
  - path_regex: secrets/.*
    key_groups:
      - age: [*nixos]
EOF

install -d -m 0755 "$secrets_dir"

encrypt() {
  local name=$1 source=$2
  local dest="$secrets_dir/$name"
  if [[ ! -e $source ]]; then
    echo "Skipping $name: $source does not exist" >&2
    return 0
  fi
  if [[ -e $dest && ${FORCE:-0} != 1 ]]; then
    echo "Keeping existing secrets/$name (FORCE=1 re-encrypts)" >&2
    return 0
  fi
  # Creation rules are matched against the input path, which lives in /etc or
  # /root. Override it with the destination so `secrets/.*` matches and sops
  # finds .sops.yaml by walking up from the repo.
  SOPS_AGE_KEY_FILE="$key" sops \
    --encrypt --input-type binary --output-type binary --age "$recipient" \
    --filename-override "$dest" --output "$dest" "$source"
  echo "Encrypted $source -> secrets/$name"
}

for name in "${!sources[@]}"; do
  encrypt "$name" "${sources[$name]}"
done

# Keep files editable by the repository owner, not root.
for name in "${!sources[@]}"; do
  [[ -e "$secrets_dir/$name" ]] || continue
  chown --reference="$repo/flake.nix" "$secrets_dir/$name"
  SOPS_AGE_KEY_FILE="$key" sops --decrypt "$secrets_dir/$name" >/dev/null
done
chown --reference="$repo/flake.nix" "$repo/.sops.yaml" "$secrets_dir"

cat <<EOF

Done. Next:
  cd "$repo"
  git add .sops.yaml secrets
  nrs
EOF
