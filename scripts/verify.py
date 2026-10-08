#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Shared local/CI entry point. Godot can exit 0 after a script error."""
from pathlib import Path
import os,re,subprocess,sys
root=Path(__file__).resolve().parents[1]
os.chdir(root)
engine=os.environ.get('GODOT','godot')
import json
expected=json.loads((root/'release/toolchain.json').read_text())['version']
version=subprocess.check_output([engine,'--version'],text=True).strip()
if version!=expected: raise SystemExit(f'Expected {expected}; found {version}')
COMMAND_TIMEOUT_SECONDS=120
def run(args, failure=False):
    try:
        result=subprocess.run(args,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=COMMAND_TIMEOUT_SECONDS)
    except subprocess.TimeoutExpired as error:
        output=error.stdout or ''
        print(output)
        raise SystemExit(f'Verification timed out after {COMMAND_TIMEOUT_SECONDS}s: {args}')
    print(result.stdout)
    if failure:
        if result.returncode==0 or 'intentional test-runner failure' not in result.stdout:
            raise SystemExit('Test runner did not signal its deliberate failure')
    elif result.returncode or re.search(r'(SCRIPT ERROR:|^ERROR:|^WARNING:|Unicode parsing error|FAIL:)',result.stdout,re.M):
        raise SystemExit('Verification failed: '+str(args))
run(['python3', '-m', 'unittest', 'discover', '-s', 'tests', '-p', 'test_*.py'])
run(['node','--test','tests/service_worker.test.mjs','tests/playing_bridge.test.mjs','tests/host_bridge.test.mjs'])
run(['python3', 'scripts/generate_audio_fixtures.py'])
run([engine,'--headless','--path','.','--import'])
run([engine,'--headless','--path','.','--editor','--quit-after','60'])
run([engine,'--headless','--path','.','--script','res://tests/run_all.gd'])
run([engine,'--headless','--path','.','--script','res://tests/run_all.gd','--','--self-test-failure'],True)
run([engine,'--headless','--path','.','--script','res://tests/live_input.gd'])
run([engine,'--headless','--path','.','--script','res://tests/pitch_detection.gd'])
run([engine,'--headless','--path','.','--script','res://tests/tuner_response.gd'])
run([engine,'--headless','--path','.','--script','res://tests/microphone_fixtures.gd'])
run([engine,'--headless','--path','.','--script','res://tests/audio_commands.gd'])
run([engine,'--headless','--path','.','--script','res://tests/synth_audio.gd'])
run([engine,'--headless','--path','.','--script','res://tests/part_audio.gd'])
run([engine,'--headless','--path','.','--script','res://tests/audio_effects.gd'])
run([engine,'--headless','--path','.','--script','res://tests/practice_ui.gd'])
run([engine,'--headless','--path','.','--script','res://tests/layout_ui.gd'])
run([engine,'--headless','--path','.','--script','res://tests/interface_ui.gd'])
run([engine,'--headless','--path','.','--script','res://tests/practice_navigation.gd'])
run([engine,'--headless','--path','.','--script','res://tests/local_state.gd'])
run([engine,'--headless','--path','.','--script','res://tests/theater_ui.gd'])
run([engine,'--headless','--path','.','--script','res://tests/page_follow_ui.gd'])
run([engine,'--headless','--path','.','--quit-after','10'])
run(['git','diff','--check'])
print('PASS: pinned engine, import, editor, core/UI tests, failure exit, application boot, whitespace')
