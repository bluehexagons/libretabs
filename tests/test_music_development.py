# SPDX-License-Identifier: Apache-2.0
"""Meaningful file/signal, source-preservation and development-readiness checks."""
from __future__ import annotations

from array import array
from fractions import Fraction
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
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import development_ready
import generate_audio_fixtures as fixtures
import review_score
import compare_library_review


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

    def test_pdf_readiness_is_optional_and_independent_of_music_tools(self):
        lock = json.loads((ROOT / "release/toolchain.json").read_text())
        with tempfile.TemporaryDirectory() as root:
            data = Path(root)
            templates = data / "godot/export_templates" / lock["template_directory"]
            templates.mkdir(parents=True)
            for name in ("web_debug.zip", "web_release.zip", "web_nothreads_release.zip"):
                (templates / name).touch()
            with patch.object(development_ready.subprocess, "run", return_value=subprocess.CompletedProcess(
                [], 0, lock["version"], "",
            )), patch.object(development_ready.shutil, "which", side_effect=lambda name:
                             None if name in development_ready.PDF_TOOLS else "/bin/" + name):
                self.assertTrue(development_ready.inspect("godot", data, True)["ok"])
                report = development_ready.inspect("godot", data, require_pdf_tools=True)
                self.assertFalse(report["ok"])
                self.assertEqual(report["missing_pdf_tools"], list(development_ready.PDF_TOOLS))


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
        destination = Path(argv[argv.index("-o") + 1])
        destination.write_bytes(b'<score-partwise><part id="P1"><measure number="1"/></part></score-partwise>'
                                if destination.suffix == ".musicxml" else b"%PDF-1.4\nmock inspection artifact\n")
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

    def test_musicxml_export_is_recorded_and_invalid_xml_blocks_success(self):
        with patch.object(review_score.subprocess, "run", side_effect=self.fake_converter):
            pdf = review_score.review(self.source, self.output, musicxml=True)
        report = json.loads((pdf.parent / "review.json").read_text())
        self.assertEqual(report["review_musicxml"], "review.musicxml")
        self.assertEqual(len(report["commands"]), 2)
        for invalid in (b"not XML", b"<score-partwise/>", b"<other/>",
                        '<score-partwise/>'.encode('utf-16'),
                        b'<!DOCTYPE score-partwise [<!ENTITY e "bad">]><score-partwise/>'):
            def convert(argv, **kwargs):
                result = self.fake_converter(argv, **kwargs)
                if ".musicxml" in argv[-2]:
                    Path(argv[-2]).write_bytes(invalid)
                return result
            with patch.object(review_score.subprocess, "run", side_effect=convert), self.assertRaises(ValueError):
                review_score.review(self.source, self.output, musicxml=True)
        self.assertEqual(len(list(self.output.rglob("review.json"))), 1)
        self.assertEqual(self.source.read_bytes(), self.data)

    def test_library_retains_failures_and_reviews_the_remaining_files(self):
        library = Path(self.directory) / "library"
        library.mkdir()
        (library / "a.mid").write_bytes(b"invalid MIDI")
        (library / "b.mid").write_bytes(self.data)
        (library / "c.mid").write_bytes(self.data)
        with patch.object(review_score.subprocess, "run", side_effect=self.fake_converter):
            path = review_score.review_library(library, self.output, musicxml=True)
        report = json.loads(path.read_text())
        self.assertFalse(report["ok"])
        self.assertEqual([score["ok"] for score in report["scores"]], [False, True, True])
        self.assertIn("MIDI", report["scores"][0]["error"])
        for score in report["scores"][1:]:
            self.assertTrue((path.parent / score["receipt"]).is_file())
        self.assertEqual((library / "a.mid").read_bytes(), b"invalid MIDI")
        self.assertEqual((library / "b.mid").read_bytes(), self.data)

    def test_empty_or_excessive_library_is_rejected_without_launch(self):
        with patch.object(review_score, "MAX_LIBRARY_SCORES", 0), patch.object(
            review_score.subprocess, "run",
        ) as execute, self.assertRaises(ValueError):
            review_score.review_library(Path(self.directory), self.output)
        execute.assert_not_called()
        with self.assertRaises(ValueError):
            review_score.review_library(Path(self.directory) / "absent", self.output)

    def test_pdf_inspection_missing_tools_or_failure_blocks_success(self):
        with patch.object(review_score.shutil, "which", return_value=None), patch.object(
            review_score.subprocess, "run",
        ) as execute, self.assertRaisesRegex(ValueError, "--pdf-tools"):
            review_score.review(self.source, self.output, inspect_pdf_output=True)
        execute.assert_not_called()
        with patch.object(review_score, "find_pdf_tools", return_value={"pdfinfo": "/bin/pdfinfo"}), patch.object(
            review_score.subprocess, "run", side_effect=self.fake_converter,
        ), patch.object(review_score, "inspect_pdf", side_effect=ValueError("broken PDF")), self.assertRaisesRegex(
            ValueError, "broken PDF",
        ):
            review_score.review(self.source, self.output, inspect_pdf_output=True)
        self.assertFalse(any(self.output.rglob("review.json")))
        self.assertEqual(self.source.read_bytes(), self.data)


class PdfInspection(unittest.TestCase):
    def setUp(self):
        self.task = Path(self.enterContext(tempfile.TemporaryDirectory()))
        self.pdf = self.task / "review.pdf"
        self.data = b"%PDF-1.4\nmock PDF\n"
        self.pdf.write_bytes(self.data)
        self.tools = {name: "/bin/" + name for name in development_ready.PDF_TOOLS}
        self.pages = "1"
        self.dimensions = (1131, 1600)
        self.failure = None

    def process(self, argv, **kwargs):
        if argv[-1] == "-v":
            return subprocess.CompletedProcess(argv, 0, "", "Poppler test version")
        self.assertNotIn("shell", kwargs)
        self.assertEqual(kwargs["timeout"], 30)
        self.assertEqual(kwargs["env"]["LC_ALL"], "C")
        tool = Path(argv[0]).name
        if tool == self.failure:
            return subprocess.CompletedProcess(argv, 1)
        if tool == "pdfinfo":
            kwargs["stdout"].write(f"Pages: {self.pages}\n".encode())
        elif tool == "pdftotext":
            self.assertEqual(argv[1:6], ["-f", "1", "-l", "1", "-layout"])
            Path(argv[-1]).write_text("First page\n")
        elif tool == "pdftoppm":
            self.assertEqual(argv[1:5], ["-f", "1", "-l", "1"])
            self.assertIn("1600", argv)
            Path(argv[-1] + ".png").write_bytes(b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR" +
                b"".join(value.to_bytes(4, "big") for value in self.dimensions))
        return subprocess.CompletedProcess(argv, 0)

    def test_preview_receipt_geometry_version_and_immutable_pdf(self):
        with patch.object(review_score.subprocess, "run", side_effect=self.process):
            result = review_score.inspect_pdf(self.pdf, self.tools)
        self.assertEqual(result["pages"], 1)
        self.assertEqual(result["rendered_pages"], [1])
        self.assertEqual(result["preview_dimensions"], [1131, 1600])
        self.assertEqual(result["pdf_sha256"], hashlib.sha256(self.data).hexdigest())
        self.assertEqual(set(result["versions"]), set(self.tools))
        self.assertEqual(self.pdf.read_bytes(), self.data)

    def test_invalid_page_counts_stop_before_text_or_rasterization(self):
        for pages in ("0", "65", "unknown"):
            self.pages = pages
            with self.subTest(pages=pages), patch.object(
                review_score.subprocess, "run", side_effect=self.process,
            ) as execute, self.assertRaisesRegex(ValueError, "1–64"):
                review_score.inspect_pdf(self.pdf, self.tools)
            self.assertEqual(execute.call_count, 4)  # Versions and metadata only.

    def test_tool_failures_and_timeout_retain_logs(self):
        for tool in self.tools:
            self.failure = tool
            with self.subTest(tool=tool), patch.object(review_score.subprocess, "run", side_effect=self.process), self.assertRaisesRegex(
                ValueError, "PDF inspection failed",
            ):
                review_score.inspect_pdf(self.pdf, self.tools)
            self.assertIn(tool, (self.task / "pdf-inspection.log").read_text())
        with patch.object(review_score.subprocess, "run", side_effect=subprocess.TimeoutExpired("pdfinfo", 10)), self.assertRaises(ValueError):
            review_score.inspect_pdf(self.pdf, self.tools)

    def test_invalid_geometry_and_changed_pdf_are_rejected(self):
        for dimensions in ((0, 1600), (1601, 1600)):
            self.dimensions = dimensions
            with patch.object(review_score.subprocess, "run", side_effect=self.process), self.assertRaisesRegex(ValueError, "geometry"):
                review_score.inspect_pdf(self.pdf, self.tools)
        self.dimensions = (1131, 1600)
        def changed(argv, **kwargs):
            result = self.process(argv, **kwargs)
            if Path(argv[0]).name == "pdftoppm" and argv[-1] != "-v":
                self.pdf.write_bytes(b"user edit")
            return result
        with patch.object(review_score.subprocess, "run", side_effect=changed), self.assertRaisesRegex(ValueError, "changed"):
            review_score.inspect_pdf(self.pdf, self.tools)
        self.assertEqual(self.pdf.read_bytes(), b"user edit")

    def test_size_limit_prevents_tool_launch(self):
        with patch.object(review_score, "MAX_PDF_BYTES", 1), patch.object(
            review_score.subprocess, "run",
        ) as execute, self.assertRaisesRegex(ValueError, "32 MiB"):
            review_score.inspect_pdf(self.pdf, self.tools)
        execute.assert_not_called()


class LibraryNotationComparison(unittest.TestCase):
    def test_exact_intervals_rejoin_ties_keep_rests_and_read_accidentals(self):
        part = ET.fromstring('''<part><measure><attributes><divisions>2</divisions></attributes>
          <note><rest/><duration>1</duration></note>
          <note><pitch><step>F</step><alter>1</alter><octave>4</octave></pitch>
            <duration>3</duration><tie type="start"/></note></measure>
          <measure><note><pitch><step>F</step><alter>1</alter><octave>4</octave></pitch>
            <duration>2</duration><tie type="stop"/></note>
          <note><pitch><step>F</step><alter>1</alter><octave>4</octave></pitch>
            <duration>1</duration></note></measure></part>''')
        self.assertEqual(compare_library_review.melody_intervals(part),
                         [(66, Fraction(1, 2), Fraction(3)), (66, Fraction(3), Fraction(7, 2))])

    def test_richer_notation_and_bad_ties_are_reported_instead_of_guessed(self):
        for extra in ('<chord/>', '<grace/>', '<tie type="stop"/>', '<tie type="start"/>', '<tie type="other"/>'):
            part = ET.fromstring(f'''<part><measure><attributes><divisions>1</divisions></attributes>
              <note><pitch><step>C</step><octave>4</octave></pitch><duration>1</duration>
              {extra}</note></measure></part>''')
            with self.subTest(extra=extra), self.assertRaises(ValueError):
                compare_library_review.melody_intervals(part)
        for extra in ('<backup><duration>1</duration></backup>',
                      '<attributes><transpose><chromatic>12</chromatic></transpose></attributes>'):
            with self.assertRaises(ValueError):
                compare_library_review.melody_intervals(ET.fromstring(f'<part><measure>{extra}</measure></part>'))
        with self.assertRaisesRegex(ValueError, 'voices/staves'):
            compare_library_review.melody_intervals(ET.fromstring('''<part><measure>
              <attributes><divisions>1</divisions></attributes>
              <note><rest/><duration>1</duration><voice>1</voice></note>
              <note><rest/><duration>1</duration><voice>2</voice></note>
              </measure></part>'''))

    def test_complete_recipe_comparison_distinguishes_release_from_pitch_and_checks_hashes(self):
        with tempfile.TemporaryDirectory() as root:
            batch = Path(root)
            for key, song in compare_library_review.SONGS.items():
                task = batch / key / "score-test"
                task.mkdir(parents=True)
                source = ROOT / 'content/library' / f'{key}.mid'
                (task / 'review.json').write_text(json.dumps({
                    'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
                }))
                tree = ET.Element('score-partwise')
                part = ET.SubElement(tree, 'part', id='P1')
                measure = ET.SubElement(part, 'measure')
                attributes = ET.SubElement(measure, 'attributes')
                ET.SubElement(attributes, 'divisions').text = '480'
                time = ET.SubElement(attributes, 'time')
                ET.SubElement(time, 'beats').text = str(song['meter'][0])
                ET.SubElement(time, 'beat-type').text = str(song['meter'][1])
                ET.SubElement(measure, 'sound', tempo=str(song['tempo']))
                # Project-authored synthetic music/XML data: CC0-1.0.
                spellings = ('C', 'C', 'D', 'D', 'E', 'F', 'F', 'G', 'G', 'A', 'A', 'B')
                for value, duration in song['notes']:
                    note = ET.SubElement(measure, 'note')
                    if value is None:
                        ET.SubElement(note, 'rest')
                    else:
                        pitch = ET.SubElement(note, 'pitch')
                        ET.SubElement(pitch, 'step').text = spellings[value % 12]
                        ET.SubElement(pitch, 'alter').text = str(int(value % 12 in (1, 3, 6, 8, 10)))
                        ET.SubElement(pitch, 'octave').text = str(value // 12 - 1)
                    ET.SubElement(note, 'duration').text = str(duration)
                ET.SubElement(tree, 'part', id='P2')
                ET.ElementTree(tree).write(task / 'review.musicxml', encoding='utf-8')
            report = compare_library_review.inspect(batch)
            self.assertTrue(all(song['pitch_and_onset_match'] and song['meter_match'] and song['tempo_match']
                                and not song['interval_differences'] for song in report['songs']))
            path = batch / 'twinkle/score-test/review.musicxml'
            tree = ET.parse(path)
            final_duration = tree.findall('part/measure/note/duration')[-1]
            final_duration.text = str(int(final_duration.text) + 120)
            tree.write(path)
            twinkle = next(song for song in compare_library_review.inspect(batch)['songs'] if song['song'] == 'twinkle')
            self.assertTrue(twinkle['pitch_and_onset_match'])
            self.assertEqual(len(twinkle['interval_differences']), 1)
            tree.findall('part/measure/note/pitch/step')[-1].text = 'D'
            tree.write(path)
            twinkle = next(song for song in compare_library_review.inspect(batch)['songs'] if song['song'] == 'twinkle')
            self.assertFalse(twinkle['pitch_and_onset_match'])
            (batch / 'twinkle/score-test/review.json').write_text('{"source_sha256":"stale"}')
            with self.assertRaisesRegex(ValueError, 'mismatch'):
                compare_library_review.inspect(batch)


if __name__ == "__main__":
    unittest.main()
