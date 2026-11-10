#!/usr/bin/env python3
"""Regenerate opencode.json from the Nix-provided base config and the local proxy."""

import json
import os
import sys
import tempfile
import urllib.request
from pathlib import Path

CONFIG_HOME = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
OPENCODE_DIR = CONFIG_HOME / "opencode"
BASE = Path(os.environ.get("OPENCODE_PROXY_BASE", OPENCODE_DIR / "opencode-proxy-base.json"))
TARGET = Path(os.environ.get("OPENCODE_PROXY_CONFIG", OPENCODE_DIR / "opencode.json"))
KEY_FILE = Path(os.environ.get("OPENCODE_PROXY_API_KEY_FILE", OPENCODE_DIR / "proxy-api-key"))
MODELS_URL = os.environ.get("OPENCODE_PROXY_MODELS_URL", "http://127.0.0.1:8080/v1/models")
PROVIDER = "opencode-unlimited-proxy"


def load_json(path):
    try:
        return json.loads(path.read_text())
    except FileNotFoundError:
        return None


def provider_models(config):
    providers = config.get("providers", config.get("provider", {}))
    return set(providers.get(PROVIDER, {}).get("models", {}))


def fetch_models():
    try:
        key = KEY_FILE.read_text().strip()
        request = urllib.request.Request(
            MODELS_URL, headers={"Authorization": f"Bearer {key}"}
        )
        # Ignore ambient proxy settings: the endpoint is always local.
        opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
        with opener.open(request, timeout=5) as response:
            payload = json.load(response)
        return {
            model["id"]: model
            for model in payload.get("data", [])
            if model.get("id")
        }
    except Exception as error:
        print(f"opencode-proxy-sync: cannot fetch {MODELS_URL}: {error}", file=sys.stderr)
        return None


def model_entry(model):
    metadata = model.get("metadata") or {}
    entry = {}

    reasoning = model.get("reasoning", model.get("supports_reasoning"))
    if reasoning is None:
        reasoning = metadata.get("reasoning")
    if reasoning is not None:
        entry["reasoning"] = bool(reasoning)

    tool_call = model.get("tool_call", metadata.get("tool_call"))
    if tool_call is not None:
        entry["tool_call"] = bool(tool_call)

    input_modalities = model.get("input_modalities") or metadata.get("input_modalities")
    output_modalities = (
        model.get("output_modalities") or metadata.get("output_modalities")
    )
    modalities = {}
    if input_modalities:
        modalities["input"] = input_modalities
    if output_modalities:
        modalities["output"] = output_modalities
    if modalities:
        entry["modalities"] = modalities
        if any(kind != "text" for kind in input_modalities or []):
            entry["attachment"] = True

    context = (
        model.get("context_length")
        or model.get("context_window")
        or metadata.get("context_window")
    )
    output = model.get("max_output") or metadata.get("max_output")
    if context and output:
        limit = {"context": context, "output": output}
        max_input = model.get("max_input") or metadata.get("max_input")
        if max_input:
            limit["input"] = max_input
        entry["limit"] = limit

    cost = model.get("cost") or metadata.get("cost") or {}
    prices = {}
    for source, target in (
        ("input", "input"),
        ("output", "output"),
        ("cache_read", "cache_read"),
        ("cacheRead", "cache_read"),
        ("cache_write", "cache_write"),
        ("cacheWrite", "cache_write"),
    ):
        if source in cost and target not in prices:
            prices[target] = cost[source]
    if "input" in prices and "output" in prices:
        entry["cost"] = prices

    return entry


def main():
    base = load_json(BASE)
    if base is None:
        # Before the first rebuild there is no base file; reuse the live config.
        base = load_json(TARGET)
    if base is None:
        print(
            f"opencode-proxy-sync: no config at {BASE} or {TARGET}; skipping",
            file=sys.stderr,
        )
        return 0

    previous_models = provider_models(load_json(TARGET) or {})
    models = fetch_models()

    provider_key = "providers" if "providers" in base else "provider"
    proxy = base.setdefault(provider_key, {}).setdefault(PROVIDER, {})
    if models:
        proxy["models"] = {
            model: model_entry(data) for model, data in sorted(models.items())
        }

    current_models = provider_models(base)
    added = sorted(current_models - previous_models)
    removed = sorted(previous_models - current_models)

    OPENCODE_DIR.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(
        dir=OPENCODE_DIR, prefix=".opencode.json.", suffix=".tmp"
    )
    try:
        with os.fdopen(fd, "w") as handle:
            json.dump(base, handle, indent=2)
            handle.write("\n")
        os.chmod(temporary, 0o600)
        os.replace(temporary, TARGET)
    except BaseException:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass
        raise

    source = "proxy" if models else "fallback"
    changes = []
    if added:
        changes.append("added " + ", ".join(added))
    if removed:
        changes.append("removed " + ", ".join(removed))
    suffix = f" ({'; '.join(changes)})" if changes else ""
    print(
        f"opencode-proxy-sync: {len(current_models)} {source} models -> {TARGET}{suffix}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
