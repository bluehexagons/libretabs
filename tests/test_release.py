# SPDX-License-Identifier: Apache-2.0
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import zipfile
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
def module(name):
    spec = importlib.util.spec_from_file_location(name, ROOT / 'scripts' / (name + '.py'))
    loaded = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(loaded)
    return loaded

release = module('release')
publish = module('publish_release')
installer = module('install_toolchain')

class ReleaseTests(unittest.TestCase):
    def test_version_refuses_paths_and_shell_input(self):
        for version in ['../escape', 'v1.0', '1.0.0', '1.0.0-prototype.1;echo bad', '1.0.0-prototype.1\n']:
            self.assertIsNone(release.VERSION.fullmatch(version))
        self.assertIsNotNone(release.VERSION.fullmatch('0.1.0-prototype.1'))

    def test_release_request_reports_actionable_version_and_notes_errors(self):
        script = ROOT / 'scripts' / 'validate_release_request.py'
        invalid = subprocess.run(
            [sys.executable, script, 'v0.1.0'], text=True,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT
        )
        self.assertNotEqual(invalid.returncode, 0)
        self.assertIn("no leading 'v'", invalid.stdout)
        self.assertIn('0.0.1-prototype.1', invalid.stdout)

        missing = subprocess.run(
            [sys.executable, script, '99.99.99-prototype.99'], text=True,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT
        )
        self.assertNotEqual(missing.returncode, 0)
        self.assertIn('Missing release notes:', missing.stdout)

        valid = subprocess.run(
            [sys.executable, script, '0.0.1-prototype.1'], text=True,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT
        )
        self.assertEqual(valid.returncode, 0, valid.stdout)
        self.assertIn('Release request is valid', valid.stdout)

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

    def test_github_publish_stages_a_draft_before_making_it_public(self):
        with tempfile.TemporaryDirectory() as temporary:
            folder = Path(temporary)
            version = '0.1.0-prototype.1'
            archive = folder / f'libretabs-{version}-web.zip'
            archive.write_bytes(b'archive')
            manifest = {'version': version, 'commit': 'a' * 40, 'artifacts': [
                {'target': 'web', 'file': archive.name, 'bytes': archive.stat().st_size,
                 'sha256': release.digest(archive)}
            ]}
            (folder / 'manifest.json').write_text(json.dumps(manifest))
            (folder / 'SHA256SUMS').write_text(''.join(
                f'{release.digest(folder / name)}  {name}\n'
                for name in [archive.name, 'manifest.json']
            ))
            notes = folder / 'notes.md'
            notes.write_text('reviewed notes')
            with patch('sys.argv', ['publish_release.py', 'github', str(folder),
                                     '--notes', str(notes), '--publish']), \
                    patch('builtins.print') as printed:
                publish.main()
            commands = [call.args[0] for call in printed.call_args_list]
            self.assertEqual(len(commands), 2)
            self.assertIn('release create', commands[0])
            self.assertIn('--draft', commands[0])
            self.assertIn('release edit', commands[1])
            self.assertIn('--draft=false', commands[1])

    def test_all_targets_have_presets_and_release_templates(self):
        presets = (ROOT / 'export_presets.cfg').read_text()
        for target in release.TARGETS.values():
            self.assertIn('name="' + target['preset'] + '"', presets)
            self.assertIn(target['entry'], target['required'])
            self.assertTrue(target['templates'])
        shell = (ROOT / 'src/platform/web_shell.html').read_text()
        self.assertNotIn('Service worker already exists.', shell)
        self.assertIn('window.location.reload();', shell)
        self.assertIn('progressive_web_app/ensure_cross_origin_isolation_headers=true', presets)

    def test_promotion_rejects_inconsistent_inventory_and_symlinks(self):
        for case in ('extra', 'missing', 'duplicate', 'malformed', 'symlink', 'boolean_size', 'unknown_target'):
            with self.subTest(case=case), tempfile.TemporaryDirectory() as temporary:
                folder = Path(temporary)
                filename = 'libretabs-0.1.0-prototype.1-web.zip'
                artifact = folder / filename
                artifact.write_bytes(b'archive')
                entry = {'target':'web', 'file':filename, 'bytes':7, 'sha256':release.digest(artifact)}
                if case == 'boolean_size':
                    entry['bytes'] = True
                if case == 'unknown_target':
                    entry['target'] = '../other'
                manifest = {'version':'0.1.0-prototype.1', 'commit':'a'*40, 'artifacts':[entry]}
                (folder / 'manifest.json').write_text(json.dumps(manifest))
                sums = ''.join(f'{release.digest(folder / name)}  {name}\n' for name in [filename, 'manifest.json'])
                if case == 'extra':
                    sums += 'a'*64 + '  unrelated.txt\n'
                elif case == 'missing':
                    sums = sums.splitlines()[0] + '\n'
                elif case == 'duplicate':
                    sums += sums.splitlines()[0] + '\n'
                elif case == 'malformed':
                    sums = 'invalid checksum\n'
                elif case == 'symlink':
                    artifact.rename(folder / 'outside.zip')
                    artifact.symlink_to(folder / 'outside.zip')
                (folder / 'SHA256SUMS').write_text(sums)
                with self.assertRaises(ValueError):
                    publish.verified_manifest(folder)

    def test_web_only_template_installation(self):
        with tempfile.TemporaryDirectory() as temporary:
            folder = Path(temporary)
            editor = folder / installer.LOCK['editor']['file']
            with zipfile.ZipFile(editor, 'w') as archive:
                archive.writestr(editor.stem, b'fake engine')
            templates = folder / 'templates.zip'
            with zipfile.ZipFile(templates, 'w') as archive:
                for target in release.TARGETS.values():
                    for name in target['templates']:
                        archive.writestr('templates/' + name, b'fake template')
            with patch.object(installer, 'download', side_effect=lambda kind, _: editor if kind == 'editor' else templates), \
                    patch('sys.argv', ['install_toolchain.py', '--directory', str(folder / 'engine'), '--templates', '--targets', 'web']), \
                    patch.dict('os.environ', {'XDG_DATA_HOME':str(folder / 'data'), 'GITHUB_ENV':''}):
                installer.main()
            installed = folder / 'data/godot/export_templates' / installer.LOCK['template_directory']
            self.assertEqual({path.name for path in installed.iterdir()}, set(release.TARGETS['web']['templates']))

if __name__ == '__main__':
    unittest.main()
