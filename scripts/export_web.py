#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Build a VM deployment from staged source without requiring .git metadata."""
import os
from pathlib import Path
import shutil
import sys

from release import LOCK, ROOT, TARGETS, run, validate_payload


def main():
    engine = os.environ.get('GODOT')
    if not engine:
        directory = Path.home() / '.cache/libretabs-toolchain'
        run([sys.executable, ROOT / 'scripts/install_toolchain.py', '--directory', directory, '--templates', '--targets', 'web'])
        engine = str(directory / Path(LOCK['editor']['file']).stem)
    if run([engine, '--version']) != LOCK['version']:
        raise SystemExit('GODOT must match release/toolchain.json')
    output = ROOT / 'exports/web'
    output.mkdir(parents=True, exist_ok=False)
    run([sys.executable, ROOT / 'scripts/prepare_export.py'])
    run([engine, '--headless', '--path', ROOT, '--import'])
    run([engine, '--headless', '--path', ROOT, '--export-release', 'Web', output / 'index.html'])
    validate_payload(output, TARGETS['web'])
    licenses = output / 'licenses'
    licenses.mkdir()
    for name in ('LICENSE', 'LICENSES/CC0-1.0.txt', 'third_party/README.md',
                 'assets/fonts/Bravura-LICENSE.txt', 'assets/fonts/Nunito-LICENSE.txt',
                 'assets/fonts/Godot-template-LICENSE.txt'):
        shutil.copy2(ROOT / name, licenses / Path(name).name)
    shutil.copy2(ROOT / 'LICENSES/README.md', licenses / 'LICENSE-SCOPE.md')
    run([engine, '--headless', '--path', ROOT, '--script', 'res://scripts/engine_notices.gd',
         '--', licenses / 'GODOT-NOTICES.txt'])
    print(output)


if __name__ == '__main__':
    main()
