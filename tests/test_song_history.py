# SPDX-License-Identifier: Apache-2.0
"""Bundled history must cover the library and retain reviewable citations."""
import ast
import json
from pathlib import Path
import re
import unittest
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]


class SongHistoryTests(unittest.TestCase):
    def test_every_song_has_localized_history_and_arrangement(self):
        data = json.loads((ROOT / 'content/library/song_history.json').read_text())
        songs = set(re.findall(r'\{"file": "([^"]+)"', (ROOT / 'src/ui/app.gd').read_text()))
        translations = dict((key, ast.literal_eval(value)) for key, value in re.findall(
            r'msgid "([A-Z0-9_]+)"\nmsgstr ("[^\n]*")', (ROOT / 'i18n/en.po').read_text()))
        self.assertEqual(data['version'], 1)
        self.assertEqual(set(data['entries']), songs)
        for name, entry in data['entries'].items():
            with self.subTest(song=name):
                for field in ['history_key', 'arrangement_key']:
                    text = translations[entry[field]]
                    self.assertGreater(len(text), 40)
                    self.assertNotIn('pending', text.lower())
                self.assertTrue(entry['sources'] or name == 'piano_study')
                for source in entry['sources']:
                    url = urlparse(source['url'])
                    self.assertEqual(url.scheme, 'https')
                    self.assertTrue(url.hostname)
                    self.assertFalse(url.username or url.password)
                    self.assertTrue(translations[source['title_key']])
                    self.assertTrue(source['supports'])
                if name != 'piano_study':
                    self.assertTrue(entry['research_notes'])

    def test_disputed_attributions_stay_qualified(self):
        # Protect researched corrections from catalog copy drifting back to myths.
        po = (ROOT / 'i18n/en.po').read_text()
        def history(name):
            return ast.literal_eval(re.search(r'msgid "SONG_HISTORY_' + name + r'"\nmsgstr ("[^\n]*")', po)[1])
        self.assertIn('Christian Petzold', history('MINUET_IN_G'))
        self.assertIn('uncertain', history('FUR_ELISE'))
        self.assertIn('Jane Taylor', history('TWINKLE'))
        self.assertIn('not securely identified', history('SAKURA_SAKURA'))
        for name in ['JINGLE_BELLS', 'CAMPTOWN_RACES', 'OH_SUSANNA']:
            self.assertIn('blackface minstrelsy', history(name))

    def test_historical_variants_identify_the_edition_and_authorship_limits(self):
        data = json.loads((ROOT / 'content/library/song_history.json').read_text())['entries']
        po = (ROOT / 'i18n/en.po').read_text()
        translations = dict((key, ast.literal_eval(value)) for key, value in re.findall(
            r'msgid "([A-Z0-9_]+)"\nmsgstr ("[^\n]*")', po))
        straight, compound = data['row_your_boat'], data['row_your_boat_compound']
        self.assertEqual(straight['history_key'], compound['history_key'])
        self.assertNotEqual(straight['arrangement_key'], compound['arrangement_key'])
        self.assertIn('repeated-note', translations[compound['arrangement_key']])
        self.assertTrue(any('/page/n73/' in item['url'] for item in compound['sources']))
        skye = translations[data['skye_boat_song']['history_key']]
        self.assertIn('Annie Campbell MacLeod', skye)
        self.assertIn('Harold Boulton', skye)
        self.assertIn('1884', skye)
        long_ago = translations[data['long_long_ago']['history_key']]
        self.assertIn('probably between 1835 and 1837', long_ago)
        self.assertIn('Elsie Baker', long_ago)
        self.assertIn('do not establish', long_ago)
