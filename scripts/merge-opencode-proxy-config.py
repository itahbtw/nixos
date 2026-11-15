#!/usr/bin/env python3
"""Merge local OpenCode Unlimited Proxy config overrides onto a new upstream config."""

import json
import os
import pathlib
import sys


def preserve_local_overrides(base_value, local_value, current_value):
    if (
        isinstance(base_value, dict)
        and isinstance(local_value, dict)
        and isinstance(current_value, dict)
    ):
        merged = dict(current_value)
        for key in base_value.keys() | local_value.keys():
            if key not in local_value:
                if key in base_value:
                    merged.pop(key, None)
            elif key not in base_value:
                merged[key] = local_value[key]
            elif local_value[key] != base_value[key]:
                merged[key] = preserve_local_overrides(
                    base_value[key], local_value[key], current_value.get(key)
                )
        return merged
    return local_value if local_value != base_value else current_value


def main():
    if len(sys.argv) != 4:
        print(f"usage: {sys.argv[0]} BASE LOCAL CURRENT", file=sys.stderr)
        return 2

    base_path, local_path, current_path = map(pathlib.Path, sys.argv[1:])
    base = json.loads(base_path.read_text())
    local = json.loads(local_path.read_text())
    current = json.loads(current_path.read_text())

    merged = preserve_local_overrides(base, local, current)
    temporary = current_path.with_suffix(current_path.suffix + ".tmp")
    temporary.write_text(json.dumps(merged, indent=2) + "\n")
    os.chmod(temporary, 0o600)
    temporary.replace(current_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
