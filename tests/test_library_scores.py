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
        self.assertEqual(len(SONGS), 29)
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

    def test_added_melodies_keep_their_openings_and_meter(self):
        openings = {
            'amazing_grace': [(None, 960), (55, 480), (60, 720), (64, 240)],
            'london_bridge': [(67, 240), (69, 240), (67, 240), (65, 240)],
            'old_macdonald': [(60, 480), (60, 480), (60, 480), (55, 480)],
            'when_the_saints': [(None, 480), (60, 480), (64, 480), (65, 480)],
            'aura_lee': [(55, 480), (60, 480), (59, 480), (60, 480)],
            'silent_night': [(67, 720), (69, 240), (67, 480), (64, 1440)],
            'camptown_races': [(67, 240), (67, 240), (64, 240), (67, 240)],
            'au_clair_de_la_lune': [(60, 480), (60, 480), (60, 480), (62, 480)],
        }
        for key, expected in openings.items():
            with self.subTest(song=key):
                self.assertEqual(SONGS[key]['notes'][:4], expected)
        self.assertEqual(SONGS['amazing_grace']['meter'], (3, 4))
        self.assertEqual(SONGS['london_bridge']['meter'], (2, 4))
        self.assertEqual(SONGS['silent_night']['meter'], (6, 8))
        self.assertEqual(SONGS['camptown_races']['meter'], (2, 4))
        self.assertEqual(SONGS['silent_night']['notes'][-2:], [(60, 2400), (None, 480)])

    def test_second_batch_preserves_distinctive_melody_features(self):
        hot_cross = SONGS['hot_cross_buns']['notes']
        self.assertEqual({pitch for pitch, _ in hot_cross}, {60, 62, 64})
        self.assertEqual(len(hot_cross), 51)
        self.assertEqual(hot_cross[:17], hot_cross[17:34])
        self.assertEqual(hot_cross[:17], hot_cross[34:])
        self.assertEqual(SONGS['simple_gifts']['notes'][:3],
                         [(None, 1440), (55, 240), (55, 240)])
        self.assertEqual(notes(SONGS['simple_gifts']['bars'].split('|')[3], (4, 4)),
                         [(62, 480)] * 4)
        sakura = SONGS['sakura_sakura']
        self.assertEqual(sakura['notes'][:3], [(69, 480), (69, 480), (71, 960)])
        self.assertEqual({pitch % 12 for pitch, _ in sakura['notes']}, {0, 2, 4, 5, 9, 11})
        self.assertEqual(sakura['bass_roots'], [40] * 14)
        self.assertEqual(SONGS['pop_goes_the_weasel']['meter'], (6, 8))
        self.assertEqual(notes(SONGS['pop_goes_the_weasel']['bars'].split('|')[6], (6, 8)),
                         [(69, 240), (None, 480), (62, 480), (65, 240)])
        home = SONGS['home_on_the_range']
        self.assertEqual(home['meter'], (3, 4))
        self.assertEqual(len(home['bars'].split('|')), 33)
        self.assertEqual(home['notes'][-2:], [(60, 1920), (None, 960)])
        self.assertEqual(SONGS['oh_susanna']['notes'][:3],
                         [(None, 1440), (60, 240), (62, 240)])

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
