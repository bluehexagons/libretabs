# SPDX-License-Identifier: Apache-2.0
import ast
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from library_scores import SONGS, notes
from generate_fixtures import authored_melody


class LibraryScores(unittest.TestCase):
    def test_all_phrases_and_artifacts(self):
        self.assertEqual(len(SONGS), 15)
        for key, song in SONGS.items():
            with self.subTest(song=key):
                pitches, durations = zip(*song['notes'])
                self.assertGreaterEqual(len(song['bars'].split('|')), 12)
                self.assertTrue(all(40 <= p <= 84 for p in pitches if p is not None))
                self.assertEqual(sum(durations) % (1920 * song['meter'][0] // song['meter'][1]), 0)
                self.assertEqual((ROOT / 'content/library' / f'{key}.mid').read_bytes(),
                    authored_melody(song['title'], song['composer'], pitches, durations,
                        song['bass_roots'], song['tempo'], *song['meter']))
                self.assertEqual(len(song['bass_roots']), len(song['bars'].split('|')))
                self.assertTrue(all(36 <= root <= 52 for root in song['bass_roots']))

    def test_distinctive_rhythms(self):
        self.assertEqual(SONGS['canon_in_d']['notes'][:4], [(78, 480), (76, 480), (74, 480), (73, 480)])
        self.assertEqual(SONGS['fur_elise']['meter'], (3, 8))
        self.assertEqual(SONGS['fur_elise']['notes'][:4], [(None, 480), (76, 120), (75, 120), (76, 120)])
        self.assertEqual(SONGS['the_entertainer']['meter'], (2, 4))
        self.assertIn((72, 720), SONGS['the_entertainer']['notes'])  # tied across bar
        self.assertEqual(notes(SONGS['frere_jacques']['bars'].split('|')[4], (4, 4)),
                         [(67, 240), (69, 240), (67, 240), (65, 240), (64, 480), (60, 480)])
        self.assertEqual(SONGS['auld_lang_syne']['notes'][2:6], [(60, 720), (59, 240), (60, 480), (64, 480)])
        self.assertEqual(SONGS['minuet_in_g']['notes'][:5], [(62, 480), (55, 240), (57, 240), (59, 240), (60, 240)])
        self.assertEqual(SONGS['mary_had_a_little_lamb']['notes'][25], (60, 1920))
        self.assertEqual(SONGS['row_your_boat']['notes'][:4], [(60, 480), (60, 480), (60, 480), (62, 480)])
        self.assertEqual(SONGS['jingle_bells']['notes'][:3], [(64, 480), (64, 480), (64, 960)])
        self.assertEqual(SONGS['greensleeves']['meter'], (3, 4))

    def test_bad_bars_and_ties_are_rejected(self):
        for bars in ['C4 C4 C4', '~:16', 'R:8 ~:8']:
            with self.assertRaises(ValueError):
                notes(bars, (4, 4))

    def test_catalog_metadata_matches_generated_scores(self):
        source = (ROOT / 'src/ui/app.gd').read_text()
        entries = [ast.literal_eval(line.strip().rstrip(',')) for line in source.splitlines()
                   if line.strip().startswith('{"file":')]
        self.assertEqual(len(entries), len(SONGS) + 1)
        self.assertEqual({entry['file'] for entry in entries}, set(SONGS) | {'piano_study'})
        for entry in entries:
            with self.subTest(song=entry['file']):
                self.assertEqual(entry['title_key'], 'LIBRARY_' + entry['file'].upper())
                self.assertIn(entry['level'], (0, 1, 2))
                self.assertTrue(set(entry['views']) <= {'guitar', 'piano'})
                self.assertTrue(entry['views'])
                if entry['file'] == 'piano_study':
                    self.assertEqual((entry['bpm'], entry['seconds']), (88, 22))
                else:
                    song = SONGS[entry['file']]
                    self.assertEqual(entry['bpm'], song['tempo'])
                    duration = sum(length for _, length in song['notes']) / 480 * 60 / song['tempo']
                    self.assertLessEqual(abs(entry['seconds'] - duration), 0.5)
