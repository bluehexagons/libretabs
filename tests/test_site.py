# SPDX-License-Identifier: Apache-2.0
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from build_site import build, copy_player, player_link, release_download_url


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
            self.assertIn('current source build', text)
            with self.assertRaises(FileExistsError):
                build(output)

            versioned = Path(temp) / 'versioned'
            build(versioned, release_version='0.0.1-prototype.4')
            page = (versioned / 'index.html').read_text()
            self.assertIn('Evaluation prototype 0.0.1-prototype.4', page)
            self.assertIn('releases/tag/v0.0.1-prototype.4', page)

    def test_release_link_is_versioned_and_validated(self):
        self.assertEqual(release_download_url('0.0.1-prototype.4'),
                         'https://github.com/bluehexagons/libretabs/releases/tag/v0.0.1-prototype.4')
        with self.assertRaises(ValueError):
            release_download_url('version four')

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

    def test_failed_build_leaves_no_partial_site_and_can_be_retried(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source = root / 'player'
            source.mkdir()
            for name in ('index.html', 'index.js', 'index.wasm', 'index.pck'):
                (source / name).write_text(name)
            output = root / 'site'
            with self.assertRaisesRegex(ValueError, 'service.worker'):
                build(output, threaded_player=source)
            self.assertFalse(output.exists())
            self.assertEqual(list(root.glob('.libretabs-site-*')), [])
            (source / 'index.service.worker.js').write_text('worker')
            build(output, threaded_player=source)
            self.assertTrue((output / 'play/index.html').is_file())

    def test_rejects_unsafe_source_and_output_relationships(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source = root / 'player'
            source.mkdir()
            linked = root / 'linked'
            linked.symlink_to(source, target_is_directory=True)
            with self.assertRaisesRegex(ValueError, 'directory'):
                build(root / 'site', threaded_player=linked)
            self.assertFalse((root / 'site').exists())
            with self.assertRaisesRegex(ValueError, 'inside a player'):
                build(source / 'site', threaded_player=source)
            self.assertEqual(list(source.iterdir()), [])
            with self.assertRaisesRegex(ValueError, 'requires the primary'):
                build(root / 'site', compatibility_player=source)
            self.assertFalse((root / 'site').exists())


if __name__ == '__main__':
    unittest.main()
