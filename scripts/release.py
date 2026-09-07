#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Build versioned prototype archives from a clean, tracked source snapshot."""
import argparse
import hashlib
import io
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
TARGETS = json.loads((ROOT / 'release/targets.json').read_text())
LOCK = json.loads((ROOT / 'release/toolchain.json').read_text())
VERSION = re.compile(r'\d+\.\d+\.\d+-prototype\.\d+\Z')

def run(args, cwd=ROOT):
    result = subprocess.run([str(arg) for arg in args], cwd=cwd, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if result.returncode or re.search(r'(SCRIPT ERROR:|^ERROR:|FAIL:)', result.stdout, re.M):
        raise RuntimeError(result.stdout)
    return result.stdout.strip()

def digest(path):
    with path.open('rb') as source:
        return hashlib.file_digest(source, 'sha256').hexdigest()

def archive_directory(source, destination):
    with zipfile.ZipFile(destination, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in sorted(source.rglob('*')):
            if path.is_symlink():
                raise ValueError(f'Symlink in package: {path}')
            if path.is_file():
                entry = zipfile.ZipInfo(path.relative_to(source).as_posix(), (2020, 1, 1, 0, 0, 0))
                entry.create_system = 3
                entry.external_attr = (0o100755 if path.stat().st_mode & 0o111 else 0o100644) << 16
                entry.compress_type = zipfile.ZIP_DEFLATED
                archive.writestr(entry, path.read_bytes())

def validate_payload(folder, target):
    for name in target['required']:
        if not (folder / name).is_file() or (folder / name).stat().st_size == 0:
            raise ValueError(f'Missing export: {name}')
    if target['entry'] == 'index.html':
        worker = (folder / 'index.service.worker.js').read_text()
        assets = json.loads(re.search(r'const ASSETS = (.*);', worker)[1])
        for name, expected in assets.items():
            if digest(folder / name) != expected:
                raise ValueError(f'Offline manifest mismatch: {name}')
        files = [path for path in folder.rglob('*') if path.is_file()]
        if len(files) > 1000 or sum(path.stat().st_size for path in files) > 500_000_000 or any(path.stat().st_size > 200_000_000 or len(path.relative_to(folder).as_posix()) > 240 for path in files):
            raise ValueError('Web export exceeds itch.io archive limits')

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--version', required=True, help='e.g. 0.1.0-prototype.1')
    parser.add_argument('--targets', nargs='+', choices=TARGETS, default=list(TARGETS))
    parser.add_argument('--output', type=Path, default=ROOT / 'dist')
    args = parser.parse_args()
    if not VERSION.fullmatch(args.version):
        parser.error('Use MAJOR.MINOR.PATCH-prototype.NUMBER')
    if run(['git', 'status', '--porcelain', '--untracked-files=normal']):
        parser.error('Commit changes first: release inputs must be a clean tracked snapshot')
    engine = shutil.which(os.environ.get('GODOT', 'godot'))
    if not engine or run([engine, '--version']) != LOCK['version']:
        parser.error('Install the locked Godot toolchain')
    commit = run(['git', 'rev-parse', 'HEAD'])
    output = args.output.resolve() / args.version
    if output.exists():
        parser.error(f'Refusing to replace existing output: {output}')
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='libretabs-release-') as temporary:
        stage = Path(temporary) / 'source'
        stage.mkdir()
        source = subprocess.check_output(['git', 'archive', '--format=zip', 'HEAD'], cwd=ROOT)
        with zipfile.ZipFile(io.BytesIO(source)) as archive:
            archive.extractall(stage)
        project = stage / 'project.godot'
        project.write_text(re.sub(r'^config/version=.*$', 'config/version=' + json.dumps(args.version), project.read_text(), flags=re.M))
        run(['python3', 'scripts/prepare_export.py'], stage)
        run([engine, '--headless', '--path', stage, '--import'])
        bundles = Path(temporary) / 'bundles'
        bundles.mkdir()
        notices = Path(temporary) / 'GODOT-NOTICES.txt'
        run([engine, '--headless', '--path', stage, '--script', 'res://scripts/engine_notices.gd', '--', notices])
        metadata = {'version': args.version, 'commit': commit, 'engine': LOCK['version'], 'toolchain': LOCK, 'artifacts': []}
        for name in dict.fromkeys(args.targets):
            target = TARGETS[name]
            payload = Path(temporary) / name
            payload.mkdir()
            print(f'Exporting {name}', flush=True)
            run([engine, '--headless', '--path', stage, '--export-release', target['preset'], payload / target['entry']])
            if name.startswith('linux'):
                (payload / target['entry']).chmod(0o755)
            licenses = payload / 'licenses'
            licenses.mkdir()
            for source_path in ['LICENSE', 'LICENSES/CC0-1.0.txt', 'third_party/README.md', 'assets/fonts/Bravura-LICENSE.txt', 'assets/fonts/Nunito-LICENSE.txt', 'assets/fonts/Godot-template-LICENSE.txt']:
                shutil.copy2(stage / source_path, licenses / Path(source_path).name)
            shutil.copy2(notices, licenses / notices.name)
            shutil.copy2(stage / 'LICENSES/README.md', licenses / 'LICENSE-SCOPE.md')
            (payload / 'BUILD.json').write_text(json.dumps({'version': args.version, 'commit': commit, 'engine': LOCK['version'], 'target': name}, indent=2) + '\n')
            launch = 'Serve index.html over HTTPS with COOP/COEP headers; do not open via file://.' if name == 'web' else f"Extract the whole archive, then run {target['entry']}. No Godot installation is needed."
            (payload / 'README.txt').write_text(f'LibreTabs {args.version} — {name}\n{launch}\nUnsigned evaluation prototype; no installer, account, telemetry or automatic updater.\nImported MIDI stays on your device and is session-only.\nProcedural audio and simplified notation; lessons and musical review remain incomplete.\nFeedback: https://github.com/bluehexagons/libretabs/issues\nSource and release instructions: https://github.com/bluehexagons/libretabs\nLicenses and notices are in licenses/.\n')
            validate_payload(payload, target)
            filename = f'libretabs-{args.version}-{name}.zip'
            archive_directory(payload, bundles / filename)
            metadata['artifacts'].append({'target': name, 'file': filename, 'bytes': (bundles / filename).stat().st_size, 'sha256': digest(bundles / filename)})
        (bundles / 'manifest.json').write_text(json.dumps(metadata, indent=2) + '\n')
        (bundles / 'SHA256SUMS').write_text(''.join(f'{digest(path)}  {path.name}\n' for path in sorted(bundles.iterdir()) if path.is_file()))
        # Publish output only when every requested export and manifest check passed.
        shutil.copytree(bundles, output)
    print(output)

if __name__ == '__main__':
    main()
