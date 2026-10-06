# SPDX-License-Identifier: Apache-2.0
"""Meaningful file/signal, source-preservation and development-readiness checks."""
from __future__ import annotations

from array import array
import hashlib
import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import wave

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import development_ready
import generate_audio_fixtures as fixtures
import review_score


def samples(data):
    with wave.open(io.BytesIO(data), "rb") as wav:
        values = array("h", wav.readframes(wav.getnframes()))
    if sys.byteorder != "little":
        values.byteswap()
    return values


class AudioFixtures(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rendered = {signal.name: fixtures.render(signal) for signal in fixtures.SIGNALS}

    def test_pcm_headers_hashes_and_provenance(self):
        for name, (data, case) in self.rendered.items():
            with self.subTest(name=name), wave.open(io.BytesIO(data), "rb") as wav:
                self.assertEqual((wav.getnchannels(), wav.getsampwidth(), wav.getframerate(),
                                  wav.getnframes(), wav.getcomptype()), (1, 2, 48000, 432000, "NONE"))
                self.assertEqual(case["sha256"], hashlib.sha256(data).hexdigest())
                self.assertEqual(case["frames"], wav.getnframes())
                self.assertEqual(len(data), 864044)
                self.assertGreater(case["rms"], 0)

    def test_speaker_fixture_has_the_documented_tone_and_silences(self):
        data, case = self.rendered["playback_bleed"]
        values = samples(data)
        section = values[int(0.6 * fixtures.RATE):int(1.6 * fixtures.RATE)]
        crossings = sum(left <= 0 < right for left, right in zip(section, section[1:]))
        self.assertAlmostEqual(crossings, 440, delta=1)
        self.assertTrue(all(value == 0 for value in values[:int(0.5 * fixtures.RATE)]))
        self.assertTrue(all(value == 0 for value in values[int(2.5 * fixtures.RATE):int(3.5 * fixtures.RATE)]))
        self.assertEqual([note["midi_pitch"] for note in case["expected"]], [69, 69, 69])

    def test_quiet_decay_clipping_and_dc_are_present_in_actual_samples(self):
        self.assertLess(self.rendered["electronic_quiet"][1]["peak"], 0.004)
        values = samples(self.rendered["acoustic_decay"][0])
        early = max(abs(value) for value in values[int(0.6 * fixtures.RATE):int(0.7 * fixtures.RATE)])
        late = max(abs(value) for value in values[int(2.2 * fixtures.RATE):int(2.3 * fixtures.RATE)])
        self.assertGreater(early, late * 10)
        self.assertGreater(self.rendered["clipped"][1]["clipping_fraction"], 0.1)
        dc = samples(self.rendered["dc_offset"][0])
        self.assertEqual(len(set(dc)), 1)
        self.assertGreater(dc[0], 0)
        for name in ("noise_only", "clipped", "dc_offset"):
            self.assertEqual(self.rendered[name][1]["expected"], [])

    def test_determinism_manifest_and_safe_reruns(self):
        self.assertEqual(fixtures.render(fixtures.SIGNALS[0]), self.rendered["electronic_quiet"])
        with tempfile.TemporaryDirectory() as root, patch.object(
            fixtures, "render", side_effect=lambda signal: self.rendered[signal.name],
        ):
            path = Path(root)
            manifest = fixtures.generate(path)
            self.assertEqual(fixtures.generate(path), manifest)
            self.assertEqual(manifest["license"], "CC0-1.0")
            self.assertEqual(manifest["author"], "LibreTabs project")
            self.assertEqual(json.loads((path / "manifest.json").read_text()), manifest)
            target = path / "electronic_quiet.wav"
            target.write_bytes(b"user edit")
            with self.assertRaisesRegex(ValueError, "differs"):
                fixtures.generate(path)
            self.assertEqual(target.read_bytes(), b"user edit")

    def test_symlinks_are_not_followed_for_directories_or_output_files(self):
        with tempfile.TemporaryDirectory() as root:
            path = Path(root)
            (path / "real").mkdir()
            (path / "alias").symlink_to(path / "real", target_is_directory=True)
            with self.assertRaises(ValueError):
                fixtures.safe_directory(path / "alias" / "nested")
            original = path / "original"
            original.write_bytes(b"unchanged")
            (path / "alias.wav").symlink_to(original)
            with self.assertRaises(ValueError):
                fixtures.write_generated(path / "alias.wav", b"replacement")
            self.assertEqual(original.read_bytes(), b"unchanged")


class DevelopmentReadiness(unittest.TestCase):
    def test_exact_pin_and_template_presence_gate_optional_music_tools_separately(self):
        lock = json.loads((ROOT / "release/toolchain.json").read_text())
        with tempfile.TemporaryDirectory() as root:
            data = Path(root)
            templates = data / "godot/export_templates" / lock["template_directory"]
            templates.mkdir(parents=True)
            for name in ("web_debug.zip", "web_release.zip", "web_nothreads_release.zip"):
                (templates / name).write_bytes(b"presence only")
            with patch.object(development_ready.subprocess, "run", return_value=subprocess.CompletedProcess(
                [], 0, lock["version"] + "\n", "",
            )), patch.object(development_ready.shutil, "which", return_value=None):
                self.assertTrue(development_ready.inspect("godot", data)["ok"])
                self.assertFalse(development_ready.inspect("godot", data, True)["ok"])
            with patch.object(development_ready.subprocess, "run", return_value=subprocess.CompletedProcess(
                [], 0, "4.8.stable.some-new-build", "",
            )), patch.object(development_ready.shutil, "which", return_value="/bin/tool"):
                report = development_ready.inspect("godot", data)
                self.assertFalse(report["ok"])
                self.assertEqual(report["engine"]["expected"], lock["version"])
            (templates / "web_release.zip").unlink()
            with patch.object(development_ready.subprocess, "run", side_effect=FileNotFoundError("missing")):
                report = development_ready.inspect("missing", data)
                self.assertFalse(report["ok"])
                self.assertEqual(report["templates"]["missing"], ["web_release.zip"])

    def test_musescore_distro_aliases_and_version_precedence(self):
        for alias in development_ready.MUSESCORE_NAMES:
            with self.subTest(alias=alias), patch.object(
                development_ready.shutil, "which",
                side_effect=lambda name: "/bin/" + name if name == alias else None,
            ):
                self.assertEqual(development_ready.find_musescore(), "/bin/" + alias)
        with patch.object(development_ready.shutil, "which", side_effect=lambda name:
                          "/bin/" + name if name in ("musescore", "mscore3") else None):
            self.assertEqual(development_ready.find_musescore(), "/bin/mscore3")


class ScoreReview(unittest.TestCase):
    def setUp(self):
        self.directory = self.enterContext(tempfile.TemporaryDirectory())
        self.source = Path(self.directory) / "licensed input with spaces.mid"
        self.data = (ROOT / "content/fixtures/first_melody.mid").read_bytes()
        self.source.write_bytes(self.data)
        self.output = Path(self.directory) / "artifacts"
        self.enterContext(patch.object(review_score, "find_musescore", return_value="/bin/musescore3"))

    def fake_converter(self, argv, **kwargs):
        if argv[-1] == "--version":
            return subprocess.CompletedProcess(argv, 0, "MuseScore 3 test version\n", "")
        Path(argv[argv.index("-o") + 1]).write_bytes(b"%PDF-1.4\nmock inspection artifact\n")
        self.assertEqual(Path(argv[-1]).read_bytes(), self.data)
        self.assertEqual(kwargs["env"]["QT_QPA_PLATFORM"], "offscreen")
        self.assertNotIn("shell", kwargs)
        self.assertIn("--no-midi", argv)
        self.assertIn("--no-synthesizer", argv)
        self.assertEqual(kwargs["timeout"], 60)
        return subprocess.CompletedProcess(argv, 0)

    def test_review_isolated_task_copy_report_and_source_preservation(self):
        with patch.object(review_score.subprocess, "run", side_effect=self.fake_converter):
            pdf = review_score.review(self.source, self.output)
            another = review_score.review(self.source, self.output)
        self.assertNotEqual(pdf.parent, another.parent)
        self.assertEqual(self.source.read_bytes(), self.data)
        report = json.loads((pdf.parent / "review.json").read_text())
        self.assertEqual(report["source_sha256"], hashlib.sha256(self.data).hexdigest())
        self.assertIn("test version", report["version_output"])
        self.assertEqual((pdf.parent / "input.mid").read_bytes(), self.data)
        self.assertTrue((pdf.parent / "conversion.log").is_file())

    def test_rejects_invalid_or_oversized_midi_before_launch(self):
        for data in (b"not MIDI", b"x" * (review_score.MAX_INPUT_BYTES + 1),
                     b"MThd\0\0\0\6\0\0\0\0\0\0"):
            self.source.write_bytes(data)
            with patch.object(review_score.subprocess, "run") as execute, self.assertRaises(ValueError):
                review_score.review(self.source, self.output)
            execute.assert_not_called()

    def test_conversion_failure_retains_logs_and_does_not_claim_success(self):
        def fail_conversion(argv, **kwargs):
            if argv[-1] == "--version":
                return subprocess.CompletedProcess(argv, 0, "test", "")
            if isinstance(outcome, Exception):
                raise outcome
            return outcome
        for outcome in (subprocess.CompletedProcess([], 1, "", ""), subprocess.TimeoutExpired("musescore", 60)):
            with patch.object(review_score.subprocess, "run", side_effect=fail_conversion), self.assertRaises(ValueError):
                review_score.review(self.source, self.output)
        self.assertFalse(any(self.output.rglob("review.json")))
        self.assertEqual(len(list(self.output.rglob("conversion.log"))), 2)
        self.assertEqual(self.source.read_bytes(), self.data)

    def test_changed_source_is_preserved_and_invalidates_the_review_receipt(self):
        def conversion(argv, **kwargs):
            result = self.fake_converter(argv, **kwargs)
            if argv[-1] != "--version":
                self.source.write_bytes(b"concurrent user edit")
            return result
        with patch.object(review_score.subprocess, "run", side_effect=conversion), self.assertRaisesRegex(
            ValueError, "Source changed",
        ):
            review_score.review(self.source, self.output)
        self.assertEqual(self.source.read_bytes(), b"concurrent user edit")
        self.assertFalse(any(self.output.rglob("review.json")))

    def test_success_exit_without_pdf_and_invalid_pdf_are_failures(self):
        def convert(argv, **kwargs):
            if argv[-1] == "--version":
                return subprocess.CompletedProcess(argv, 0, "test", "")
            if invalid_pdf:
                Path(argv[argv.index("-o") + 1]).write_bytes(b"not a PDF")
            return subprocess.CompletedProcess(argv, 0)
        for invalid_pdf in (False, True):
            with patch.object(review_score.subprocess, "run", side_effect=convert), self.assertRaises(ValueError):
                review_score.review(self.source, self.output)
        self.assertFalse(any(self.output.rglob("review.json")))

    def test_missing_musescore_is_actionable(self):
        with patch.object(review_score, "find_musescore", return_value=None), self.assertRaisesRegex(
            ValueError, "--musescore",
        ):
            review_score.review(self.source, self.output)


if __name__ == "__main__":
    unittest.main()
