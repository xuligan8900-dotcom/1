#!/usr/bin/env python3
"""Install pinned official Linux x86_64 Rojo/Luau binaries with TLS and SHA-256."""
import hashlib
import io
import json
import os
from pathlib import Path
import platform
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
BIN = ROOT / "tools" / "bin"


def main():
    if platform.system() != "Linux" or platform.machine() not in ("x86_64", "AMD64"):
        raise SystemExit("This bootstrap targets Linux x86_64. For Studio, open the supplied rbxlx directly; see README.")
    BIN.mkdir(parents=True, exist_ok=True)
    for tool in json.loads((ROOT / "tools" / "versions.json").read_text()):
        cache = BIN / (tool["name"] + ".zip")
        payload = cache.read_bytes() if cache.exists() else urllib.request.urlopen(tool["url"], timeout=60).read()
        if hashlib.sha256(payload).hexdigest() != tool["sha256"]:
            raise SystemExit(f"Checksum mismatch for {tool['name']}; refusing extraction. Remove the cached archive and investigate.")
        cache.write_bytes(payload)
        with zipfile.ZipFile(io.BytesIO(payload)) as archive:
            for item in archive.infolist():
                target = (BIN / item.filename).resolve()
                if not target.is_relative_to(BIN.resolve()):
                    raise SystemExit("Unsafe archive member")
            archive.extractall(BIN)
            for item in archive.infolist():
                target = BIN / item.filename
                if target.is_file():
                    target.chmod(target.stat().st_mode | 0o111)
        print(f"Verified and installed {tool['name']} {tool['version']}")


if __name__ == "__main__":
    main()
