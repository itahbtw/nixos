#!/usr/bin/env bash
# Wire a route64 WireGuard tunnel into the host and point WARP at its prefix.
#
# route64 gives every free tunnel a /64 transfer network and a routed /56.
# WireGuard traverses NAT, so no DMZ or protocol-41 forwarding is needed.
#
# Usage:
#   sudo ./setup-route64-ipv6.sh --config route64.conf --routed-prefix 2a11:.../56
#
# Run it after the NixOS module has been activated (`nrs`), so the
# wg-quick-route64 unit exists. It is safe to re-run.

set -euo pipefail

wg_config=/etc/wireguard/route64.conf
prefix_env=/etc/route64-tunnel.env
proxy_env=/opt/opencode-unlimited-proxy/stack/.env

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: setup-route64-ipv6.sh --config FILE --routed-prefix PREFIX [options]

  --config FILE          WireGuard config copied from the route64 manager
                         (the Linux / wg-quick one). Required.
  --routed-prefix PREFIX The routed /56 (or /64) from the tunnel page,
                         for example 2a11:6c7:1400:af00::/56. Required.
  --warp-prefix PREFIX   The /64 WARP should bind sources from. Defaults to
                         the first /64 inside the routed prefix.
  -h, --help             Show this help.

The script writes /etc/wireguard/route64.conf, /etc/route64-tunnel.env and
WARP_SOURCE_IPV6 in the proxy .env, then restarts the tunnel.
EOF
}

source_config=
routed_prefix=
warp_prefix=

while (($#)); do
  case $1 in
    --config)
      source_config=${2:?--config needs a value}
      shift 2
      ;;
    --routed-prefix)
      routed_prefix=${2:?--routed-prefix needs a value}
      shift 2
      ;;
    --warp-prefix)
      warp_prefix=${2:?--warp-prefix needs a value}
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1 (try --help)"
      ;;
  esac
done

[[ ${EUID} -eq 0 ]] || die "run this with sudo"
[[ -n $source_config ]] || die "--config is required"
[[ -r $source_config ]] || die "cannot read $source_config"
[[ -n $routed_prefix ]] || die "--routed-prefix is required"

mapfile -t networks < <(python3 - "$routed_prefix" "$warp_prefix" <<'PY'
import ipaddress
import sys

routed = ipaddress.ip_network(sys.argv[1], strict=False)
if routed.version != 6:
    raise SystemExit(f"not an IPv6 prefix: {sys.argv[1]}")
if routed.prefixlen > 64:
    raise SystemExit(f"routed prefix must be /64 or larger: {routed}")

if sys.argv[2]:
    warp = ipaddress.ip_network(sys.argv[2], strict=False)
    if warp.version != 6 or warp.prefixlen != 64:
        raise SystemExit(f"--warp-prefix must be an IPv6 /64: {sys.argv[2]}")
    if not warp.subnet_of(routed):
        raise SystemExit(f"--warp-prefix {warp} is outside {routed}")
elif routed.prefixlen < 64:
    warp = next(routed.subnets(new_prefix=64))
else:
    warp = routed

print(routed.with_prefixlen)
print(warp.with_prefixlen)
print(routed.network_address + 1)
PY
)

routed=${networks[0]:?could not parse the routed prefix}
warp=${networks[1]:?could not derive a /64 for WARP}
probe=${networks[2]:?could not derive a probe address}

ip_bin=$(command -v ip || true)
[[ -n $ip_bin ]] || ip_bin=/run/current-system/sw/bin/ip
[[ -x $ip_bin ]] || die "iproute2 'ip' was not found"

iface=$(basename "$wg_config" .conf)

install -d -m 755 /etc/wireguard
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

python3 - "$source_config" "$tmp" "$routed" "$ip_bin" "$iface" <<'PY'
import sys

source, target, prefix, ip, iface = sys.argv[1:6]
routing_table = 51820
raw = open(source).read().splitlines()

sections = {}
order = []
current = None
for line in raw:
    stripped = line.strip()
    if stripped.startswith("[") and stripped.endswith("]"):
        current = stripped[1:-1].strip().lower()
        order.append(current)
        sections.setdefault(current, [])
    elif current is None:
        continue
    elif not stripped or stripped.startswith("#") or "=" not in stripped:
        # route64 appends prose and a test command after the peer block.
        continue
    else:
        sections[current].append(line)

if "interface" not in sections or "peer" not in sections:
    raise SystemExit("the config is missing an [Interface] or [Peer] section")


def value_of(lines, key):
    for line in lines:
        if "=" in line:
            name, value = line.split("=", 1)
            if name.strip().lower() == key:
                return value.strip()
    return None


def without(lines, keys):
    kept = []
    for line in lines:
        if "=" in line:
            name = line.split("=", 1)[0].strip().lower()
            if name in keys:
                continue
        kept.append(line)
    return kept


def trimmed(lines):
    lines = list(lines)
    while lines and not lines[-1].strip():
        lines.pop()
    while lines and not lines[0].strip():
        lines.pop(0)
    return lines


if not value_of(sections["interface"], "privatekey"):
    raise SystemExit("the config is missing PrivateKey")
if not value_of(sections["interface"], "address"):
    raise SystemExit("the config is missing Address")
if not value_of(sections["peer"], "publickey"):
    raise SystemExit("the config is missing the peer PublicKey")

interface = trimmed(
    without(sections["interface"], {"mtu", "postup", "predown", "table"})
)
peer = trimmed(without(sections["peer"], {"persistentkeepalive", "allowedips"}))

if not value_of(sections["interface"], "mtu"):
    interface.append("MTU = 1420")

# Keep the host IPv4-only: only traffic sourced from the routed prefix (the
# WARP exits bind those addresses) is sent through the tunnel.
interface.append("Table = off")
interface.append(f"PostUp = {ip} -6 route replace local {prefix} dev lo")
interface.append(
    f"PostUp = {ip} -6 route replace default dev {iface} table {routing_table}"
)
interface.append(
    f"PostUp = {ip} -6 rule del from {prefix} lookup {routing_table} priority 100 || true"
)
interface.append(
    f"PostUp = {ip} -6 rule add from {prefix} lookup {routing_table} priority 100"
)
interface.append(
    f"PreDown = {ip} -6 rule del from {prefix} lookup {routing_table} priority 100 || true"
)
interface.append(
    f"PreDown = {ip} -6 route del default dev {iface} table {routing_table} || true"
)
interface.append(f"PreDown = {ip} -6 route del local {prefix} dev lo || true")

# Table=off makes these cryptokey-routing entries only; wg-quick installs no
# routes of its own.
peer.append("AllowedIPs = ::/1, 8000::/1")
peer.append("PersistentKeepalive = 15")

output = []
preamble = trimmed(sections.get("", []))
if preamble:
    output.extend(preamble)
    output.append("")
output.append("[Interface]")
output.extend(trimmed(interface))
output.append("")
output.append("[Peer]")
output.extend(trimmed(peer))
output.append("")

open(target, "w").write("\n".join(output))
PY

install -m 600 "$tmp" "$wg_config"
chown root:root "$wg_config"

cat > "$prefix_env" <<EOF
ROUTE64_PREFIX=$routed
WARP_SOURCE_IPV6=$warp
EOF
chmod 600 "$prefix_env"
chown root:root "$prefix_env"

if [[ -f $proxy_env ]]; then
  read -r owner mode < <(stat -c '%u:%g %a' "$proxy_env")
  python3 - "$proxy_env" "$warp" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
value = sys.argv[2]
key = "WARP_SOURCE_IPV6"
lines = path.read_text().splitlines()
result = []
found = False
for line in lines:
    stripped = line.strip()
    if not stripped.startswith("#") and stripped.split("=", 1)[0].strip() == key:
        result.append(f"{key}={value}")
        found = True
    else:
        result.append(line)
if not found:
    if result and result[-1].strip():
        result.append("")
    result.append(f"{key}={value}")
path.write_text("\n".join(result) + "\n")
PY
  chown "$owner" "$proxy_env"
  chmod "$mode" "$proxy_env"
else
  echo "warning: $proxy_env does not exist; set WARP_SOURCE_IPV6=$warp there later." >&2
fi

echo "== Tunnel configuration =="
echo "  routed prefix: $routed"
echo "  WARP /64:      $warp"
echo "  probe source:  $probe"
echo "  routing:       WARP-only (source-based policy routing)"
echo "  config:        $wg_config"
echo "  proxy env:     $proxy_env"

if systemctl cat wg-quick-route64.service >/dev/null 2>&1; then
  echo "== Restarting the tunnel =="
  systemctl restart wg-quick-route64.service

  handshake=0
  for _ in {1..15}; do
    if wg show route64 latest-handshakes 2>/dev/null |
      awk '{ if ($2 + 0 > 0) seen = 1 } END { exit seen ? 0 : 1 }'; then
      handshake=1
      break
    fi
    sleep 1
  done

  if ((handshake)); then
    echo "WireGuard handshake: OK"
  else
    echo "warning: no WireGuard handshake yet; check 'journalctl -u wg-quick-route64'." >&2
  fi
else
  echo "The wg-quick-route64 unit is not installed yet."
  echo "Run 'nrs' to activate the NixOS module, then re-run this script."
fi

echo "== Local delivery route =="
"$ip_bin" -6 route show table local | grep -F "$routed" || {
  echo "warning: the local route for $routed is missing." >&2
}

echo "== WARP-only policy routing =="
routing_ok=1
if ! "$ip_bin" -6 rule show | grep -F "from $routed lookup 51820" >/dev/null; then
  echo "warning: the policy rule for $routed is missing." >&2
  routing_ok=0
fi
if ! "$ip_bin" -6 route show table 51820 2>/dev/null | grep -q '^default'; then
  echo "warning: table 51820 has no default route." >&2
  routing_ok=0
fi
if ((routing_ok)); then
  echo "policy rule and table 51820: OK"
fi

if [[ $(sysctl -n net.ipv6.ip_nonlocal_bind 2>/dev/null) == 1 ]]; then
  echo "ip_nonlocal_bind: enabled"
else
  echo "warning: net.ipv6.ip_nonlocal_bind is not 1; run 'nrs' to apply it." >&2
fi

echo "== IPv6 reachability from $probe =="
if ping -6 -c 1 -W 3 -I "$probe" 2606:4700:4700::1111 >/dev/null 2>&1; then
  echo "ICMPv6 from $probe: OK"
elif curl -6 -fsS --max-time 8 --interface "$probe" https://ifconfig.co >/dev/null 2>&1; then
  echo "IPv6 HTTPS from $probe: OK (ICMP may be filtered)"
else
  echo "warning: no IPv6 connectivity from $probe yet; check the tunnel." >&2
fi

echo
echo "Next: restart the proxy so WARP picks up the new source prefix:"
echo "  oup"
echo "Then check:"
echo "  curl -s http://127.0.0.1:8080/healthz | jq .warp"
echo "  sudo docker logs ofu-engine 2>&1 | grep -i 'egress.*ready'"
