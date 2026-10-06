#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Export a bounded MIDI task copy with external MuseScore for notation review."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile

from development_ready import find_musescore
from generate_audio_fixtures import ROOT, safe_directory

MAX_INPUT_BYTES = 1024 * 1024
TIMEOUT_SECONDS = 60


def review(source: Path, output: Path) -> Path:
    executable = find_musescore()
    if executable is None:
        raise ValueError("MuseScore is unavailable. Rerun upgraded Basaltwater setup with --musescore.")
    if not source.is_file():
        raise ValueError("Select a regular, licensed MIDI file.")
    with source.open("rb") as incoming:
        data = incoming.read(MAX_INPUT_BYTES + 1)
    if len(data) > MAX_INPUT_BYTES:
        raise ValueError("Score review is limited to MIDI files of at most 1 MiB.")
    if len(data) < 14 or data[:8] != b"MThd\x00\x00\x00\x06":
        raise ValueError("Expected a MIDI file with a six-byte MThd header.")
    if int.from_bytes(data[10:12], "big") not in range(1, 65):
        raise ValueError("Score review supports 1–64 MIDI tracks.")
    output = safe_directory(output)
    task = Path(tempfile.mkdtemp(prefix="score-", dir=output))
    input_copy = task / "input.mid"
    input_copy.write_bytes(data)
    pdf = task / "review.pdf"
    # These are isolated process settings, never global audio or desktop policy.
    environment = {**os.environ, "QT_QPA_PLATFORM": "offscreen",
                   "XDG_CONFIG_HOME": str(task / "config"), "XDG_DATA_HOME": str(task / "data"),
                   "XDG_CACHE_HOME": str(task / "cache")}
    for name in ("config", "data", "cache"):
        (task / name).mkdir()
    command = [executable, "--no-midi", "--no-synthesizer", "-o", str(pdf), str(input_copy)]
    try:
        version = subprocess.run([executable, "--version"], env=environment, capture_output=True,
                                 text=True, timeout=10, check=False)
    except (OSError, subprocess.SubprocessError) as exc:
        raise ValueError(f"MuseScore version check failed; inspect {task}: {exc}") from exc
    if version.returncode:
        raise ValueError(f"MuseScore version check failed; inspect its installation ({task}).")
    with (task / "conversion.log").open("wb") as log:
        try:
            result = subprocess.run(command, env=environment, stdout=log, stderr=subprocess.STDOUT,
                                    timeout=TIMEOUT_SECONDS, check=False)
        except (OSError, subprocess.SubprocessError) as exc:
            raise ValueError(f"MuseScore conversion failed; inspect {task}: {exc}") from exc
    if result.returncode or not pdf.is_file() or pdf.stat().st_size == 0:
        raise ValueError(f"MuseScore did not produce a review PDF; inspect {task}/conversion.log")
    with pdf.open("rb") as exported:
        if exported.read(5) != b"%PDF-":
            raise ValueError(f"MuseScore output is not a PDF; inspect {task}")
    with source.open("rb") as original:
        if original.read(MAX_INPUT_BYTES + 1) != data:
            raise ValueError(f"Source changed during review; inspect {task} before using its output.")
    report = {
        "source": str(source.resolve()), "source_sha256": hashlib.sha256(data).hexdigest(),
        "executable": executable, "argv": command, "timeout_seconds": TIMEOUT_SECONDS,
        "version_output": (version.stdout + version.stderr).strip()[:2000],
        "input_copy": input_copy.name, "review_pdf": pdf.name,
        "scope": "Derived notation for inspection; no canonical source edits or musical correctness claim.",
    }
    (task / "review.json").write_text(json.dumps(report, indent=2) + "\n")
    return pdf


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, nargs="?", default=ROOT / "content/fixtures/first_melody.mid")
    parser.add_argument("--output", type=Path, default=ROOT / "build/score-review")
    args = parser.parse_args()
    try:
        pdf = review(args.source, args.output)
    except (OSError, ValueError) as error:
        parser.exit(1, f"Score review failed: {error}\n")
    print(f"Review PDF: {pdf}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
