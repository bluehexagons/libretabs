#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Build a web deployment from staged source without requiring .git metadata."""
import argparse
from contextlib import nullcontext
import os
from pathlib import Path
import shutil
import sys

from release import LOCK, ROOT, TARGETS, VERSION, run, source_snapshot, validate_payload


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--preset', choices=('Web', 'Web single-thread comparison'),
                        default='Web')
    parser.add_argument('--output', type=Path, default=ROOT / 'exports/web')
    parser.add_argument('--version', default='', help='Stamp a tracked HEAD snapshot for a published release')
    args = parser.parse_args()
    if args.version and not VERSION.fullmatch(args.version):
        parser.error('Use MAJOR.MINOR.PATCH-prototype.NUMBER')
    engine = os.environ.get('GODOT')
    if not engine:
        directory = Path.home() / '.cache/libretabs-toolchain'
        run([sys.executable, ROOT / 'scripts/install_toolchain.py', '--directory', directory, '--templates', '--targets', 'web'])
        engine = str(directory / Path(LOCK['editor']['file']).stem)
    if run([engine, '--version']) != LOCK['version']:
        raise SystemExit('GODOT must match release/toolchain.json')
    output = args.output.resolve()
    if output == ROOT:
        parser.error('--output cannot replace the project directory')
    output.mkdir(parents=True, exist_ok=False)
    with source_snapshot(args.version) if args.version else nullcontext(ROOT) as source:
        run([sys.executable, source / 'scripts/prepare_export.py'], source)
        run([engine, '--headless', '--path', source, '--import'])
        run([engine, '--headless', '--path', source, '--export-release', args.preset, output / 'index.html'])
        validate_payload(output, TARGETS['web'])
        licenses = output / 'licenses'
        licenses.mkdir()
        for name in ('LICENSE', 'LICENSES/CC0-1.0.txt', 'third_party/README.md',
                     'assets/fonts/Bravura-LICENSE.txt', 'assets/fonts/Nunito-LICENSE.txt',
                     'assets/fonts/Godot-template-LICENSE.txt'):
            shutil.copy2(source / name, licenses / Path(name).name)
        shutil.copy2(source / 'LICENSES/README.md', licenses / 'LICENSE-SCOPE.md')
        run([engine, '--headless', '--path', source, '--script', 'res://scripts/engine_notices.gd',
             '--', licenses / 'GODOT-NOTICES.txt'], source)
    print(output)


if __name__ == '__main__':
    main()
