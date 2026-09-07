# SPDX-License-Identifier: Apache-2.0
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
def module(name):
    spec = importlib.util.spec_from_file_location(name, ROOT / 'scripts' / (name + '.py'))
    loaded = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(loaded)
    return loaded

release = module('release')
publish = module('publish_release')

class ReleaseTests(unittest.TestCase):
    def test_version_refuses_paths_and_shell_input(self):
        for version in ['../escape', 'v1.0', '1.0.0', '1.0.0-prototype.1;echo bad', '1.0.0-prototype.1\n']:
            self.assertIsNone(release.VERSION.fullmatch(version))
        self.assertIsNotNone(release.VERSION.fullmatch('0.1.0-prototype.1'))

    def test_archive_layout_permissions_and_repeatability(self):
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary)
            payload = base / 'payload'
            payload.mkdir()
            (payload / 'index.html').write_text('test')
            binary = payload / 'run'
            binary.write_text('test')
            binary.chmod(0o755)
            release.archive_directory(payload, base / 'a.zip')
            release.archive_directory(payload, base / 'b.zip')
            self.assertEqual(release.digest(base / 'a.zip'), release.digest(base / 'b.zip'))
            with zipfile.ZipFile(base / 'a.zip') as archive:
                self.assertIn('index.html', archive.namelist())
                self.assertEqual((archive.getinfo('run').external_attr >> 16) & 0o777, 0o755)

    def test_checksum_promotion_refuses_tampering(self):
        with tempfile.TemporaryDirectory() as temporary:
            folder = Path(temporary)
            filename = 'libretabs-0.1.0-prototype.1-web.zip'
            (folder / filename).write_bytes(b'archive')
            manifest = {'version':'0.1.0-prototype.1', 'commit':'a'*40, 'artifacts':[{'target':'web', 'file':filename, 'bytes':7, 'sha256':release.digest(folder / filename)}]}
            (folder / 'manifest.json').write_text(json.dumps(manifest))
            (folder / 'SHA256SUMS').write_text(''.join(f'{release.digest(folder / name)}  {name}\n' for name in [filename, 'manifest.json']))
            self.assertEqual(publish.verified_manifest(folder), manifest)
            (folder / filename).write_bytes(b'changed')
            with self.assertRaises(ValueError):
                publish.verified_manifest(folder)

    def test_all_targets_have_presets_and_release_templates(self):
        presets = (ROOT / 'export_presets.cfg').read_text()
        for target in release.TARGETS.values():
            self.assertIn('name="' + target['preset'] + '"', presets)
            self.assertIn(target['entry'], target['required'])
            self.assertTrue(target['templates'])

if __name__ == '__main__':
    unittest.main()
