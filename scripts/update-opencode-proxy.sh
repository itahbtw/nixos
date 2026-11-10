#!/usr/bin/env bash
set -euo pipefail

repo=/opt/opencode-unlimited-proxy
stack="$repo/stack"
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
merge_script="$script_dir/merge-opencode-proxy-config.py"
sync_script="$script_dir/opencode-proxy-sync.py"
validate_script="$script_dir/validate-opencode-proxy-config.py"
run_smoke=0
[[ "${1:-}" == "--smoke" ]] && run_smoke=1

if ! git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not a Git checkout: $repo" >&2
  exit 1
fi
if [[ "$(git -C "$repo" branch --show-current)" != main ]]; then
  echo "Expected the main branch; refusing to update another branch." >&2
  exit 1
fi

tmpdir=$(mktemp -d)
chmod 700 "$tmpdir"
config_saved=0
config_merged=0
pulled=0
cleanup() {
  local result=$?
  trap - EXIT
  if (( config_saved && ! config_merged )); then
    if (( pulled )) && python3 "$merge_script" \
      "$tmpdir/config.base.json" "$tmpdir/config.local.json" "$stack/config.json"; then
      chmod 600 "$stack/config.json"
      config_merged=1
    else
      install -m 600 "$tmpdir/config.local.json" "$stack/config.json"
      echo "Warning: restored the pre-update config; re-run this update to" >&2
      echo "merge new upstream defaults instead of dropping them." >&2
    fi
  fi
  rm -rf -- "$tmpdir"
  exit "$result"
}
trap cleanup EXIT

echo "== Fetching upstream =="
git -C "$repo" fetch origin

echo "== Current checkout =="
git -C "$repo" status --short --branch

# Only local config overrides may survive the update. Generated Compose files
# and their generator are checked by upstream CI, so local edits there are a
# conflict to resolve rather than something to silently discard.
while IFS= read -r entry; do
  [[ -z "$entry" ]] && continue
  case "$entry" in
    " M stack/config.json") ;;
    *)
      echo "Unexpected local change: $entry" >&2
      echo "Save or resolve it before updating; no files were changed." >&2
      exit 1
      ;;
  esac
done < <(git -C "$repo" status --porcelain)

# Preserve only local config overrides. This lets new upstream defaults such as
# the WARP settings flow into the updated config without losing the API key or
# dashboard password.
git -C "$repo" show HEAD:stack/config.json > "$tmpdir/config.base.json"
install -m 600 "$stack/config.json" "$tmpdir/config.local.json"
config_saved=1

git -C "$repo" restore --source=HEAD --staged --worktree -- stack/config.json

echo "== Updating source (fast-forward only) =="
if ! git -C "$repo" pull --ff-only; then
  echo "Git update failed; your local config will be restored." >&2
  exit 1
fi
pulled=1

# Run the repository's own checks against the freshly pulled defaults before
# merging local overrides. This is the same suite upstream CI runs and catches
# a broken config/compose before it is deployed.
echo "== Running upstream tests =="
python3 -m unittest discover -s "$repo/tests"

echo "== Merging local config overrides =="
python3 "$merge_script" \
  "$tmpdir/config.base.json" "$tmpdir/config.local.json" "$stack/config.json"
config_merged=1
chmod 600 "$stack/config.json"

echo "== Validating merged config =="
python3 "$validate_script" "$stack/config.json" "$stack/.env"

echo "== Pulling engine image and rebuilding the stack =="
sudo docker compose -f "$stack/docker-compose.yml" pull opencode-engine
sudo docker compose -f "$stack/docker-compose.yml" up -d --force-recreate --remove-orphans

echo "== Service status =="
sudo docker compose -f "$stack/docker-compose.yml" ps

api_key=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["server_keys"][0])' "$stack/config.json")
api_ready=0
quota_exhausted=0
for _ in {1..30}; do
  if curl -fs --connect-timeout 2 --max-time 5 --output /dev/null \
    --config <(printf 'header = "Authorization: Bearer %s"\n' "$api_key") \
    http://127.0.0.1:8080/v1/models; then
    health=$(curl -fs --max-time 5 http://127.0.0.1:8080/healthz 2>/dev/null || true)
    state=$(printf '%s' "$health" | python3 -c '
import json
import sys

try:
    data = json.load(sys.stdin)
except Exception:
    print("waiting")
    raise SystemExit

models = data.get("models") or {}
warp = data.get("warp") or {}
active = int(warp.get("active") or 0)
cooling = int(warp.get("cooling") or 0)

if not data.get("ready") or models.get("status") != "ready":
    print("waiting")
elif not warp:
    print("ready")
elif warp.get("status") == "ready" and active >= 1:
    print("ready")
elif active == 0 and cooling > 0:
    print("cooling")
else:
    print("waiting")
' 2>/dev/null || echo waiting)
    case "$state" in
      ready)
        api_ready=1
        break
        ;;
      cooling)
        api_ready=1
        quota_exhausted=1
        break
        ;;
    esac
  fi
  sleep 2
done
if (( api_ready )); then
  if (( quota_exhausted )); then
    echo "Warning: the API is up, but every WARP exit is cooling because the" >&2
    echo "upstream daily quota is exhausted. Retry after 00:00 UTC." >&2
  else
    echo "API is reachable, authenticated, and the model/WARP status is ready."
  fi
else
  echo "Stack updated, but readiness checks failed." >&2
  echo "Inspect http://127.0.0.1:8080/healthz and: docker logs ofu-engine" >&2
  exit 1
fi

echo "== Syncing OpenCode model list =="
python3 "$sync_script" || echo "Warning: could not sync the OpenCode model list." >&2

if (( run_smoke )); then
  echo "== Running upstream smoke test =="
  "$repo/scripts/smoke.sh" http://127.0.0.1:8080 "$api_key"
fi
