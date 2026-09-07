# SPDX-License-Identifier: Apache-2.0
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from build_site import build, copy_player, player_link


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

    def test_bundles_two_isolated_player_scopes(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            for folder in ('threaded', 'compatible'):
                source = root / folder
                source.mkdir()
                for name in ('index.html', 'index.js', 'index.wasm', 'index.pck', 'index.service.worker.js'):
                    (source / name).write_bytes((folder + name).encode())
            output = root / 'site'
            build(output, threaded_player=root / 'threaded', compatibility_player=root / 'compatible')
            page = (output / 'index.html').read_text()
            self.assertIn('href="play/"', page)
            self.assertIn('href="play-compatible/"', page)
            self.assertTrue((output / 'play/index.service.worker.js').is_file())
            self.assertTrue((output / 'play-compatible/index.service.worker.js').is_file())

    def test_rejects_incomplete_or_linked_player(self):
        with tempfile.TemporaryDirectory() as temp:
            source = Path(temp) / 'player'
            source.mkdir()
            for name in ('index.html', 'index.js', 'index.wasm', 'index.pck'):
                (source / name).write_text(name)
            with self.assertRaisesRegex(ValueError, 'service.worker'):
                copy_player(source, Path(temp) / 'output')
            (source / 'index.service.worker.js').symlink_to(source / 'index.js')
            with self.assertRaisesRegex(ValueError, 'symlink'):
                copy_player(source, Path(temp) / 'output')


if __name__ == '__main__':
    unittest.main()
