#!/usr/bin/env python3
"""Read a plist and emit deterministic, privacy-safe JSON to stdout."""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import pathlib
import plistlib
import re
import sys
from typing import Any


UUID_RE = re.compile(
    r"\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-"
    r"[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b"
)
USER_PATH_RE = re.compile(r"/Users/[^/\s]+")


def redact_text(value: str) -> str:
    value = USER_PATH_RE.sub("/Users/<USER>", value)
    return UUID_RE.sub("<UUID>", value)


def sanitize(value: Any) -> Any:
    if isinstance(value, dict):
        return {
            redact_text(str(key)): sanitize(item)
            for key, item in sorted(value.items(), key=lambda pair: str(pair[0]))
        }
    if isinstance(value, list):
        return [sanitize(item) for item in value]
    if isinstance(value, bytes):
        return {
            "_type": "data",
            "length": len(value),
            "sha256": hashlib.sha256(value).hexdigest(),
        }
    if isinstance(value, dt.datetime):
        return value.isoformat()
    if isinstance(value, str):
        return redact_text(value)
    return value


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("plist", type=pathlib.Path, help="plist to read")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        with args.plist.open("rb") as stream:
            root = plistlib.load(stream)
    except (OSError, plistlib.InvalidFileException) as error:
        print(f"sanitize_store.py: {error}", file=sys.stderr)
        return 1

    json.dump(sanitize(root), sys.stdout, indent=2, sort_keys=True)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
