# SPDX-License-Identifier: Apache-2.0
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from library_scores import SONGS, notes
from generate_fixtures import authored_melody


class LibraryScores(unittest.TestCase):
    def test_all_phrases_and_artifacts(self):
        self.assertEqual(len(SONGS), 12)
        for key, song in SONGS.items():
            with self.subTest(song=key):
                pitches, durations = zip(*song['notes'])
                self.assertGreaterEqual(len(song['bars'].split('|')), 12)
                self.assertTrue(all(40 <= p <= 84 for p in pitches if p is not None))
                self.assertEqual(sum(durations) % (1920 * song['meter'][0] // song['meter'][1]), 0)
                self.assertEqual((ROOT / 'content/library' / f'{key}.mid').read_bytes(),
                    authored_melody(song['title'], song['composer'], pitches, durations,
                        song['tempo'], *song['meter']))

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

    def test_bad_bars_and_ties_are_rejected(self):
        for bars in ['C4 C4 C4', '~:16', 'R:8 ~:8']:
            with self.assertRaises(ValueError):
                notes(bars, (4, 4))
