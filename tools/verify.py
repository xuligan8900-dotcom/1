#!/usr/bin/env python3
"""Compile all Luau, run real pure-module tests, build and inspect the Rojo place."""
from pathlib import Path
import json
import subprocess
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
BIN = ROOT / "tools" / "bin"
BUILD = ROOT / "build"


def run(*args, capture=False):
    try:
        return subprocess.run([str(a) for a in args], cwd=ROOT, check=True, text=True,
                              stdout=subprocess.PIPE if capture else None,
                              stderr=subprocess.PIPE if capture else None)
    except subprocess.CalledProcessError as error:
        if capture:
            sys.stderr.write((error.stdout or "") + (error.stderr or ""))
        raise SystemExit(error.returncode) from None


def main():
    BUILD.mkdir(exist_ok=True)
    sources = sorted([*ROOT.joinpath("src").rglob("*.luau"), *ROOT.joinpath("tests").rglob("*.luau")])
    for path in sources:
        try:
            run(BIN / "luau-compile", path, capture=True)
        except subprocess.CalledProcessError as error:
            raise SystemExit(error.stderr or error.stdout)
    print(f"PASS: {len(sources)} Luau files compiled", flush=True)
    result = run(BIN / "luau", ROOT / "tests" / "run.luau", capture=True)
    print(result.stdout, end="", flush=True)
    place = BUILD / "MechanicalTower.rbxlx"
    run(BIN / "rojo", "build", "default.project.json", "-o", place)
    xml = ET.parse(place)
    embedded = xml.findall(".//Properties/*[@name='Source']")
    expected = len(list((ROOT / "src").rglob("*.luau"))) + len(list((ROOT / "tests" / "studio").rglob("*.luau")))
    assert len(embedded) == expected, (len(embedded), expected)
    assert all(node.text and node.text.strip() for node in embedded), "Empty embedded script"
    print(f"PASS: built Roblox XML with {len(embedded)} nonempty scripts/modules", flush=True)
    report = {
        "luau_files_compiled": len(sources),
        "standalone_test_stdout": result.stdout.strip().splitlines(),
        "place_scripts": len(embedded),
        "rojo_build": "passed",
        "roblox_studio_executed": False,
        "runtime_smoke": "Included; executes on Play in Studio, not executed in cloud",
        "requires_studio": ["R15 traversal and fairness", "carrier physics under network lag",
                            "multiplayer checkpoints and respawn", "live DataStore",
                            "mobile layout", "finish effects"],
    }
    (BUILD / "verification.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")


if __name__ == "__main__":
    main()
