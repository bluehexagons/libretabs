#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Compare a MuseScore library review with current authored monophonic melodies.

Development inspection only, not a MusicXML import adapter or a musician verdict.
Durations use exact quarter-note fractions; tied fragments are rejoined.
"""
from __future__ import annotations

import argparse
from fractions import Fraction
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET

from generate_audio_fixtures import ROOT
from generate_fixtures import authored_melody
from library_scores import SONGS
from review_score import MAX_INPUT_BYTES, validate_musicxml


def melody_intervals(part: ET.Element) -> list[tuple[int, Fraction, Fraction]]:
    """Read this corpus's single voice; reject richer notation rather than guess."""
    notes: list[tuple[int, Fraction, Fraction]] = []
    divisions = 0
    position = Fraction(0)
    active: tuple[int, int] | None = None
    voice: tuple[str, str] | None = None
    for measure in part.findall("measure"):
        for item in measure:
            if item.tag == "attributes":
                divisions = int(item.findtext("divisions", str(divisions)))
                if item.find("transpose") is not None:
                    raise ValueError("Transposing instruments are outside this inspection contract.")
            if item.tag in ("backup", "forward"):
                raise ValueError("Multiple voices or shifted cursors need a separate review.")
            if item.tag != "note":
                continue
            if divisions <= 0 or item.find("chord") is not None or item.find("grace") is not None:
                raise ValueError("Expected metered single notes/rests with positive divisions.")
            identity = (item.findtext("voice", "1"), item.findtext("staff", "1"))
            if voice is not None and voice != identity:
                raise ValueError("Multiple voices/staves need a separate review.")
            voice = identity
            duration = Fraction(int(item.findtext("duration", "0")), divisions)
            if duration <= 0:
                raise ValueError("Expected positive note/rest duration.")
            pitch = item.find("pitch")
            if pitch is None:
                if item.find("rest") is None or active is not None:
                    raise ValueError("Unsupported unpitched note or rest within a tie.")
            else:
                value = (int(pitch.findtext("octave")) + 1) * 12
                value += {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}[pitch.findtext("step")]
                value += int(pitch.findtext("alter", "0"))
                ties = {tie.get("type") for tie in item.findall("tie")}
                if ties - {"start", "stop"}:
                    raise ValueError("Unsupported tie type.")
                if "stop" in ties:
                    if active is None or active[0] != value or notes[active[1]][2] != position:
                        raise ValueError("Unmatched or discontinuous tie.")
                    start = notes[active[1]][1]
                    notes[active[1]] = (value, start, position + duration)
                else:
                    if active is not None:
                        raise ValueError("A tied note was not continued.")
                    notes.append((value, position, position + duration))
                active = (value, len(notes) - 1) if "start" in ties else None
            position += duration
    if active is not None:
        raise ValueError("Unclosed tie.")
    return notes


def inspect(batch: Path) -> dict:
    results = []
    for key, song in sorted(SONGS.items()):
        # Every task has a fresh random name. Require exactly one successful
        # receipt per known song, and keep artifact reads within that song folder.
        directory = batch / key
        receipts = list(directory.glob("score-*/review.json"))
        if len(receipts) != 1:
            raise ValueError(f"Expected one successful review for {key}.")
        receipt_path = receipts[0]
        receipt = json.loads(receipt_path.read_text())
        source = ROOT / "content/library" / f"{key}.mid"
        with source.open("rb") as incoming:
            data = incoming.read(MAX_INPUT_BYTES + 1)
        pitches, durations = zip(*song["notes"])
        authored = authored_melody(song["title"], song["composer"], pitches, durations,
                                  song["bass_roots"], song["tempo"], *song["meter"])
        digest = hashlib.sha256(data).hexdigest()
        if data != authored or receipt.get("source_sha256") != digest:
            raise ValueError(f"{key}: source/recipe/review mismatch; regenerate the review before comparing.")
        xml = receipt_path.parent / "review.musicxml"
        if not xml.resolve().is_relative_to(batch.resolve()):
            raise ValueError("Review artifact points outside the batch.")
        tree = validate_musicxml(xml)
        parts = tree.findall("part")
        if len(parts) != 2:
            raise ValueError(f"{key}: expected separate melody and bass parts.")
        actual = melody_intervals(parts[0])
        expected = []
        tick = 0
        for pitch, duration in song["notes"]:
            if pitch is not None:
                expected.append((pitch, Fraction(tick, 480), Fraction(tick + duration, 480)))
            tick += duration
        differences = []
        for index in range(max(len(expected), len(actual))):
            before = expected[index] if index < len(expected) else None
            after = actual[index] if index < len(actual) else None
            if before != after:
                differences.append({"note_index": index, "source": before, "notation": after})
        time = parts[0].find("measure/attributes/time")
        meter = (int(time.findtext("beats")), int(time.findtext("beat-type"))) if time is not None else None
        tempo = tree.find(".//sound[@tempo]")
        bpm = float(tempo.get("tempo")) if tempo is not None else None
        results.append({"song": key, "source_sha256": digest,
                        "tool_version": receipt.get("version_output"),
                        "musicxml_sha256": hashlib.sha256(xml.read_bytes()).hexdigest(),
                        "source_notes": len(expected), "notation_notes": len(actual),
                        "pitch_and_onset_match": len(expected) == len(actual) and all(
                            before[:2] == after[:2] for before, after in zip(expected, actual)),
                        "meter_match": meter == song["meter"],
                        "tempo_match": bpm is not None and abs(bpm - song["tempo"]) < 0.01,
                        "interval_differences": differences})
    return {"scope": "29 authored melody recipes only; piano study and bass articulation need separate inspection. "
                     "Differences describe the external importer, not a verdict on canonical MIDI or LibreTabs.",
            "songs": results}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("batch", type=Path, help="library-* directory from review_score.py --library --musicxml")
    args = parser.parse_args()
    try:
        report = inspect(args.batch)
    except (OSError, ValueError, KeyError, TypeError) as error:
        parser.exit(1, f"Comparison failed: {error}\n")
    print(json.dumps(report, indent=2, default=str))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
