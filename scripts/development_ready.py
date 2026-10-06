#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Read-only project engine/template and optional music-tool readiness."""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
MUSESCORE_NAMES = ("musescore4", "mscore4", "musescore3", "mscore3", "musescore", "mscore")
MUSIC_TOOLS = ("sox", "soxi", "arecord", "aplay", "amidi", "aconnect", "pactl", "ffmpeg", "ffprobe")


def find_musescore() -> str | None:
    return next((path for name in MUSESCORE_NAMES if (path := shutil.which(name))), None)


def inspect(engine: str, data_home: Path, require_music_tools: bool = False) -> dict:
    lock = json.loads((ROOT / "release/toolchain.json").read_text())
    observed = None
    error = None
    try:
        result = subprocess.run([engine, "--version"], capture_output=True, text=True, timeout=10)
        observed = result.stdout.strip() if result.returncode == 0 else None
        if result.returncode:
            error = f"Godot version query failed ({result.returncode})"
    except (OSError, subprocess.SubprocessError) as exc:
        error = str(exc)
    template_dir = data_home / "godot/export_templates" / lock["template_directory"]
    template_files = ("web_debug.zip", "web_release.zip", "web_nothreads_release.zip")
    missing_templates = [name for name in template_files if not (template_dir / name).is_file()]
    tools = {name: shutil.which(name) for name in MUSIC_TOOLS}
    tools["musescore"] = find_musescore()
    missing_tools = [name for name, path in tools.items() if path is None]
    return {
        "ok": observed == lock["version"] and not missing_templates and
              (not require_music_tools or not missing_tools),
        "engine": {"expected": lock["version"], "observed": observed, "error": error},
        "templates": {"directory": str(template_dir), "missing": missing_templates,
                      "scope": "file presence; export validates contents"},
        "music_tools": tools, "missing_music_tools": missing_tools,
        "music_tools_required": require_music_tools,
        "device_readiness": "unverified; tools do not establish microphone, MIDI or playback devices",
        "guidance": "Retain the project pin. Use scripts/install_toolchain.py for an isolated pinned toolchain "
                    "if host updates change Godot. Rerun upgraded Basaltwater setup with "
                    "--musescore --audio-tools --av-tools for optional music utilities.",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--engine", default=os.environ.get("GODOT", "godot"))
    parser.add_argument("--data-home", type=Path,
                        default=Path(os.environ.get("XDG_DATA_HOME", str(Path.home() / ".local/share"))))
    parser.add_argument("--require-music-tools", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    report = inspect(args.engine, args.data_home, args.require_music_tools)
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        print(f"Godot: expected {report['engine']['expected']}; found {report['engine']['observed'] or 'unavailable'}")
        print("Missing templates: " + (", ".join(report["templates"]["missing"]) or "none"))
        print("Missing optional music tools: " + (", ".join(report["missing_music_tools"]) or "none"))
        print(report["guidance"])
        print(report["device_readiness"])
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
