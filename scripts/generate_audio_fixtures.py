#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Generate project-authored CC0 PCM input fixtures; no recordings or samples."""
from __future__ import annotations

import argparse
from array import array
from dataclasses import dataclass
import hashlib
import io
import json
import math
from pathlib import Path
import random
import sys
import wave

ROOT = Path(__file__).resolve().parents[1]
RATE = 48000
DURATION = 9
SEED = 24026
GENERATOR_VERSION = 1
SEGMENTS = ((0.5, 2.5, 57), (3.5, 5.5, 69), (6.5, 8.5, 76))


@dataclass(frozen=True)
class Signal:
    name: str
    amplitude: float
    decay: float = 0
    noise: float = 0
    offset: float = 0
    harmonics: bool = True
    kind: str = "notes"
    profile: str = "electronic_piano"


SIGNALS = (
    Signal("electronic_quiet", 0.003, decay=0.3, noise=0.00001, offset=0.0001),
    Signal("acoustic_decay", 0.12, decay=2.0, noise=0.00003, profile="acoustic_piano"),
    Signal("playback_bleed", 0.08, harmonics=False, kind="bleed"),
    Signal("noise_only", 0, noise=0.003, kind="reject"),
    Signal("clipped", 2.0, harmonics=False, kind="reject"),
    Signal("dc_offset", 0, offset=0.02, kind="reject"),
)


def render(signal: Signal) -> tuple[bytes, dict]:
    """A fixed nine-second, mono 16-bit waveform with explicit expectations."""
    rng = random.Random(SEED)
    pcm = array("h")
    energy = 0.0
    peak = 0
    clipped = 0
    for frame in range(RATE * DURATION):
        at = frame / RATE
        value = signal.offset + signal.noise * rng.uniform(-1, 1)
        for start, end, pitch in SEGMENTS:
            if start <= at < end:
                pitch = 69 if signal.kind == "bleed" else pitch
                elapsed = at - start
                hz = 440 * 2 ** ((pitch - 69) / 12)
                phase = math.tau * hz * elapsed
                tone = math.sin(phase)
                if signal.harmonics:
                    tone = (tone + 0.8 * math.sin(2 * phase) + 0.2 * math.sin(3 * phase)) / 2
                envelope = min(1, elapsed / 0.01, (end - at) / 0.01) * math.exp(-signal.decay * elapsed)
                value += signal.amplitude * envelope * tone
                break
        sample = round(max(-1, min(1, value)) * 32767)
        pcm.append(sample)
        energy += (sample / 32768) ** 2
        peak = max(peak, abs(sample))
        clipped += abs(sample) >= 32113  # detector rejects peaks >= 0.98
    if sys.byteorder != "little":
        pcm.byteswap()
    with io.BytesIO() as output:
        with wave.open(output, "wb") as wav:
            wav.setnchannels(1)
            wav.setsampwidth(2)
            wav.setframerate(RATE)
            wav.writeframes(pcm.tobytes())
        data = output.getvalue()
    expected = [] if signal.kind == "reject" else [
        {"start": start, "end": end, "midi_pitch": 69 if signal.kind == "bleed" else pitch}
        for start, end, pitch in SEGMENTS
    ]
    return data, {
        "file": signal.name + ".wav", "sha256": hashlib.sha256(data).hexdigest(),
        "frames": RATE * DURATION, "sample_rate": RATE, "channels": 1, "sample_bits": 16,
        "rms": math.sqrt(energy / (RATE * DURATION)), "peak": peak / 32768,
        "clipping_fraction": clipped / (RATE * DURATION),
        "profile": signal.profile, "sensitivity": 100, "expected": expected,
        "purpose": "demonstrate tonal speaker pickup; source identity is unknowable from pitch"
                   if signal.kind == "bleed" else signal.name.replace("_", " "),
    }


def safe_directory(path: Path) -> Path:
    """Never traverse a symlink or replace an existing non-directory."""
    path = path.absolute()
    for parent in (*reversed(path.parents), path):
        if parent.is_symlink() or (parent.exists() and not parent.is_dir()):
            raise ValueError(f"Unsafe artifact directory: {parent}")
    path.mkdir(parents=True, exist_ok=True)
    return path


def write_generated(path: Path, data: bytes) -> None:
    """Reruns accept identical artifacts and refuse changed/user-owned files."""
    if path.is_symlink():
        raise ValueError(f"Refusing symlinked artifact: {path}")
    if path.exists():
        if not path.is_file() or path.stat().st_size != len(data) or path.read_bytes() != data:
            raise ValueError(f"Artifact differs; inspect and remove it before regenerating: {path}")
        return
    with path.open("xb") as target:
        target.write(data)


def generate(directory: Path) -> dict:
    directory = safe_directory(directory)
    cases = []
    for signal in SIGNALS:
        data, case = render(signal)
        write_generated(directory / case["file"], data)
        cases.append(case)
    manifest = {
        "version": GENERATOR_VERSION, "license": "CC0-1.0", "author": "LibreTabs project",
        "seed": SEED, "reference_hz": 440, "duration_seconds": DURATION, "cases": cases,
        "limits": "Synthesized signals only; no physical capture, device gain or latency qualification.",
    }
    write_generated(directory / "manifest.json", (json.dumps(manifest, indent=2) + "\n").encode())
    return manifest


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / "build/audio-fixtures")
    args = parser.parse_args()
    try:
        manifest = generate(args.output)
    except (OSError, ValueError) as error:
        parser.exit(1, f"Audio fixture generation failed: {error}\n")
    print(f"Generated {len(manifest['cases'])} CC0 fixtures in {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
