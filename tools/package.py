#!/usr/bin/env python3
"""Package tested source and the current built place; excludes binaries and caches."""
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "build"
files = [ROOT / "README.md", ROOT / "default.project.json", ROOT / ".gitignore"]
for folder in ("src", "docs", "tests"):
    files.extend(sorted((ROOT / folder).rglob("*.luau" if folder != "docs" else "*.md")))
files.extend(p for p in (ROOT / "tools").iterdir() if p.is_file())
archive = BUILD / "MechanicalTower-50-Stages.zip"
with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as output:
    for path in files:
        output.write(path, path.relative_to(ROOT).as_posix())
    output.write(BUILD / "MechanicalTower.rbxlx", "MechanicalTower.rbxlx")
    output.write(BUILD / "verification.json", "verification.json")
    output.write(BUILD / "MechanicalTower-v7.0.rbxlx", "MechanicalTower-v7.0.rbxlx")
with zipfile.ZipFile(archive) as output:
    assert output.testzip() is None
    print(f"Verified archive: {len(output.namelist())} files, {archive.stat().st_size} bytes")
