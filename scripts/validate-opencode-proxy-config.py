#!/usr/bin/env python3
"""Validate the merged OpenCode Unlimited Proxy stack configuration."""

import json
import pathlib
import sys

LOOPBACK_HOSTS = {"127.0.0.1", "localhost", "::1"}


def read_env(path):
    values = {}
    if path.exists():
        for line in path.read_text().splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                key, value = line.split("=", 1)
                values[key.strip()] = value.strip()
    return values


def main():
    if len(sys.argv) != 3:
        print(f"usage: {sys.argv[0]} CONFIG ENV", file=sys.stderr)
        return 2

    config = json.loads(pathlib.Path(sys.argv[1]).read_text())
    env = read_env(pathlib.Path(sys.argv[2]))

    warnings = []
    errors = []

    warp = config.get("warp") or {}
    if warp.get("enabled"):
        if env.get("WARP_ACCEPT_TOS") != "1":
            errors.append(
                "WARP is enabled but WARP_ACCEPT_TOS=1 is not set in stack/.env "
                "(Cloudflare terms)."
            )
        source = (warp.get("source_ipv6") or env.get("WARP_SOURCE_IPV6") or "").strip()
        if warp.get("stack") == "ipv6" and not source:
            warnings.append(
                "warp.stack is ipv6 but no routed /64 is configured "
                "(WARP_SOURCE_IPV6 or warp.source_ipv6); exits may share the "
                "host's IPv4 NAT bucket instead of getting separate quota blocks."
            )

    keys = [
        key for key in config.get("server_keys") or [] if isinstance(key, str) and key
    ]
    if not keys:
        errors.append("server_keys is empty; the local API has no key.")
    elif any("local-test-key" in key for key in keys):
        warnings.append(
            "server_keys still uses the shipped placeholder; change it in "
            "stack/config.json."
        )

    webui = config.get("webui") or {}
    if webui.get("password") in (None, "", "changeme-changeme"):
        warnings.append(
            "webui.password is the shipped default; change it in stack/config.json."
        )

    listen = config.get("listen", "")
    host = listen.rsplit(":", 1)[0].strip("[]")
    if config.get("anonymous") and host not in LOOPBACK_HOSTS:
        errors.append(f"anonymous gateway listens on {listen!r}, which is not loopback.")

    for message in warnings:
        print(f"warning: {message}", file=sys.stderr)
    for message in errors:
        print(f"error: {message}", file=sys.stderr)
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
