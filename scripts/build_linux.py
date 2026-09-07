#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Self-contained development package using the pinned installed engine.

The managed VM has web templates, but no Linux export template. Shipping the
same engine with an exported PCK provides an honest unsigned development build.
"""
from pathlib import Path
import os,shutil,subprocess,zipfile
root=Path(__file__).resolve().parents[1];os.chdir(root)
engine=Path(shutil.which(os.environ.get('GODOT','godot'))).resolve()
if subprocess.check_output([str(engine),'--version'],text=True).strip()!='4.7.2.stable.official.ed1daf0bf':
    raise SystemExit('Install the pinned Godot build first')
out=root/'exports/linux';out.mkdir(parents=True,exist_ok=True)
result=subprocess.run([str(engine),'--headless','--path','.', '--export-pack','Linux',str(out/'libretabs.pck')],text=True,capture_output=True)
if result.returncode or 'ERROR:' in result.stdout+result.stderr: raise SystemExit(result.stdout+result.stderr)
shutil.copy2(engine,out/'godot')
launcher=out/'run.sh';launcher.write_text('#!/bin/sh\ncd -- "$(dirname -- "$0")" || exit 1\nexec ./godot --main-pack libretabs.pck "$@"\n');launcher.chmod(0o755)
shutil.copy2(root/'LICENSE',out/'LICENSE-Apache-2.0.txt')
shutil.copy2(root/'assets/fonts/Bravura-LICENSE.txt',out/'Bravura-LICENSE.txt')
(out/'README.txt').write_text('LibreTabs M0 development prototype. Linux x86_64.\nRun ./run.sh (or sh run.sh). No install or account required.\nThe package includes the Godot editor-capable engine because this VM has no native export template. It starts directly in the app.\nUse Licenses & notices in the app for the Godot runtime and dependency notices.\nOriginal MIDI fixtures are CC0-1.0.\n')
subprocess.run([str(engine),'--headless','--path','.', '--script','res://scripts/engine_notices.gd','--',str(out/'GODOT-NOTICES.txt')],check=True)
with zipfile.ZipFile(root/'exports/libretabs-linux-x86_64.zip','w',zipfile.ZIP_DEFLATED) as archive:
    for p in sorted(out.iterdir()):
        if p.is_file():archive.write(p,'libretabs/'+p.name)
print(root/'exports/libretabs-linux-x86_64.zip')
