#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Install checksum-locked Linux build tools; templates are opt-in."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
LOCK = json.loads((ROOT / 'release/toolchain.json').read_text())

def download(kind, cache):
    item = LOCK[kind]
    path = cache / item['file']
    if not path.exists() or hashlib.file_digest(path.open('rb'), 'sha256').hexdigest() != item['sha256']:
        temporary = path.with_suffix('.download')
        url = f"https://github.com/godotengine/godot-builds/releases/download/{LOCK['release']}/{item['file']}"
        with urllib.request.urlopen(url, timeout=120) as source, temporary.open('wb') as target:
            shutil.copyfileobj(source, target)
        if hashlib.file_digest(temporary.open('rb'), 'sha256').hexdigest() != item['sha256']:
            temporary.unlink()
            raise SystemExit(f'Checksum mismatch: {kind}')
        temporary.replace(path)
    return path

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--directory', type=Path, required=True)
    parser.add_argument('--templates', action='store_true')
    targets = json.loads((ROOT / 'release/targets.json').read_text())
    parser.add_argument('--targets', nargs='+', choices=targets,
                        help='Extract templates only for these targets (default: all)')
    args = parser.parse_args()
    if args.targets and not args.templates:
        parser.error('--targets requires --templates')
    directory = args.directory.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    archive = download('editor', directory)
    executable = directory / archive.stem
    with zipfile.ZipFile(archive) as source:
        with source.open(archive.stem) as data, executable.open('wb') as out:
            shutil.copyfileobj(data, out)
    executable.chmod(0o755)
    if args.templates:
        names = {name for key in (args.targets or targets) for name in targets[key]['templates']}
        destination = Path(os.environ.get('XDG_DATA_HOME', Path.home() / '.local/share')) / 'godot/export_templates' / LOCK['template_directory']
        destination.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(download('templates', directory)) as source:
            for name in sorted(names):
                with source.open('templates/' + name) as data, (destination / name).open('wb') as out:
                    shutil.copyfileobj(data, out)
    if os.environ.get('GITHUB_ENV'):
        with open(os.environ['GITHUB_ENV'], 'a') as env:
            env.write(f'GODOT={executable}\n')
    print(executable)

if __name__ == '__main__':
    main()
