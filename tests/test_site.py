# SPDX-License-Identifier: Apache-2.0
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from build_site import build, player_link


class SiteTests(unittest.TestCase):
    def test_only_public_site_files_are_built(self):
        with tempfile.TemporaryDirectory() as temp:
            output = Path(temp) / 'site'
            build(output)
            self.assertEqual({p.name for p in output.iterdir()}, {'index.html', 'style.css', '.nojekyll'})
            text = (output / 'index.html').read_text()
            self.assertNotIn('{{', text)
            self.assertNotIn('href=""', text)
            self.assertIn('Evaluation prototype', text)
            with self.assertRaises(FileExistsError):
                build(output)

    def test_optional_links_are_validated_and_escaped(self):
        for url in ('javascript:alert(1)', 'http://example.com', 'https://a:b@example.com',
                    'https://example.com/\n', 'https://example.com\\@other.example'):
            with self.subTest(url=url), self.assertRaises(ValueError):
                player_link(url, 'Play')
        self.assertIn('&amp;', player_link('https://example.com/?a=1&b=2', 'Play'))
        self.assertIn('&quot;', player_link('https://example.com/?a="hi"', 'Play'))


if __name__ == '__main__':
    unittest.main()
