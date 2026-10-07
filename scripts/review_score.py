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
import xml.etree.ElementTree as ET

from development_ready import find_musescore
from generate_audio_fixtures import ROOT, safe_directory

MAX_INPUT_BYTES = 1024 * 1024
TIMEOUT_SECONDS = 60
MAX_XML_BYTES = 16 * 1024 * 1024
MAX_LIBRARY_SCORES = 64


def validate_musicxml(path: Path) -> ET.Element:
    """Check a local converter artifact without loading external DTDs/entities."""
    with path.open("rb") as exported:
        data = exported.read(MAX_XML_BYTES + 1)
    if len(data) > MAX_XML_BYTES or b"<!ENTITY" in data or b"\x00" in data:
        raise ValueError(f"MusicXML is oversized, declares entities or has an unsupported encoding; inspect {path.parent}")
    try:
        root = ET.fromstring(data)
    except ET.ParseError as exc:
        raise ValueError(f"MuseScore output is not valid MusicXML; inspect {path.parent}") from exc
    if root.tag != "score-partwise" or root.find("part/measure") is None:
        raise ValueError(f"Expected a partwise MusicXML score with measures; inspect {path.parent}")
    return root


def review(source: Path, output: Path, *, musicxml: bool = False) -> Path:
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
    commands = [command]
    xml = task / "review.musicxml"
    if musicxml:
        commands.append([executable, "--no-midi", "--no-synthesizer", "-o", str(xml), str(input_copy)])
    with (task / "conversion.log").open("wb") as log:
        for conversion in commands:
            log.write((json.dumps(conversion) + "\n").encode())
            log.flush()
            try:
                result = subprocess.run(conversion, env=environment, stdout=log, stderr=subprocess.STDOUT,
                                        timeout=TIMEOUT_SECONDS, check=False)
            except (OSError, subprocess.SubprocessError) as exc:
                raise ValueError(f"MuseScore conversion failed; inspect {task}: {exc}") from exc
            if result.returncode:
                raise ValueError(f"MuseScore conversion failed; inspect {task}/conversion.log")
    if not pdf.is_file() or pdf.stat().st_size == 0:
        raise ValueError(f"MuseScore did not produce a review PDF; inspect {task}/conversion.log")
    with pdf.open("rb") as exported:
        if exported.read(5) != b"%PDF-":
            raise ValueError(f"MuseScore output is not a PDF; inspect {task}")
    if musicxml:
        if not xml.is_file():
            raise ValueError(f"MuseScore did not produce MusicXML; inspect {task}/conversion.log")
        validate_musicxml(xml)
    with source.open("rb") as original:
        if original.read(MAX_INPUT_BYTES + 1) != data:
            raise ValueError(f"Source changed during review; inspect {task} before using its output.")
    report = {
        "source": str(source.resolve()), "source_sha256": hashlib.sha256(data).hexdigest(),
        "executable": executable, "argv": command, "timeout_seconds": TIMEOUT_SECONDS,
        "commands": commands,
        "version_output": (version.stdout + version.stderr).strip()[:2000],
        "input_copy": input_copy.name, "review_pdf": pdf.name,
        "scope": "Derived notation for inspection; no canonical source edits or musical correctness claim.",
    }
    if musicxml:
        report["review_musicxml"] = xml.name
    (task / "review.json").write_text(json.dumps(report, indent=2) + "\n")
    return pdf


def review_library(library: Path, output: Path, *, musicxml: bool = False) -> Path:
    """Retain every conversion failure; conversion success is not a music verdict."""
    sources = sorted(library.glob("*.mid"))
    if not 1 <= len(sources) <= MAX_LIBRARY_SCORES:
        raise ValueError(f"Expected 1–{MAX_LIBRARY_SCORES} library MIDI files.")
    batch = Path(tempfile.mkdtemp(prefix="library-", dir=safe_directory(output)))
    results = []
    for source in sources:
        try:
            pdf = review(source, batch / source.stem, musicxml=musicxml)
            results.append({"source": str(source.resolve()), "ok": True,
                            "receipt": str((pdf.parent / "review.json").relative_to(batch))})
        except (OSError, ValueError) as exc:
            results.append({"source": str(source.resolve()), "ok": False, "error": str(exc)})
    report = {"ok": all(result["ok"] for result in results), "scores": results,
              "scope": "External conversion only; inspect notation before making a musical correctness claim."}
    receipt = batch / "library.json"
    receipt.write_text(json.dumps(report, indent=2) + "\n")
    return receipt


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, nargs="?")
    parser.add_argument("--output", type=Path, default=ROOT / "build/score-review")
    parser.add_argument("--musicxml", action="store_true", help="Also retain structured derived notation for comparison")
    parser.add_argument("--library", action="store_true", help="Review every bundled library MIDI, retaining failures")
    args = parser.parse_args()
    if args.library and args.source is not None:
        parser.error("Choose either a source or --library.")
    try:
        if args.library:
            receipt = review_library(ROOT / "content/library", args.output, musicxml=args.musicxml)
            print(f"Library conversion report: {receipt}")
            return 0 if json.loads(receipt.read_text())["ok"] else 1
        pdf = review(args.source or ROOT / "content/fixtures/first_melody.mid", args.output,
                     musicxml=args.musicxml)
    except (OSError, ValueError) as error:
        parser.exit(1, f"Score review failed: {error}\n")
    print(f"Review PDF: {pdf}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
