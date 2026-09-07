#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Shared local/CI entry point. Godot can exit 0 after a script error."""
from pathlib import Path
import os,re,subprocess,sys
root=Path(__file__).resolve().parents[1]
os.chdir(root)
engine=os.environ.get('GODOT','godot')
expected='4.7.2.stable.official.ed1daf0bf'
version=subprocess.check_output([engine,'--version'],text=True).strip()
if version!=expected: raise SystemExit(f'Expected {expected}; found {version}')
def run(args, failure=False):
    result=subprocess.run(args,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    print(result.stdout)
    if failure:
        if result.returncode==0 or 'intentional test-runner failure' not in result.stdout:
            raise SystemExit('Test runner did not signal its deliberate failure')
    elif result.returncode or re.search(r'(SCRIPT ERROR:|^ERROR:|^WARNING:|Unicode parsing error|FAIL:)',result.stdout,re.M):
        raise SystemExit('Verification failed: '+str(args))
run([engine,'--headless','--path','.','--import'])
run([engine,'--headless','--path','.','--editor','--quit-after','60'])
run([engine,'--headless','--path','.','--script','res://tests/run_all.gd'])
run([engine,'--headless','--path','.','--script','res://tests/run_all.gd','--','--self-test-failure'],True)
run([engine,'--headless','--path','.','--script','res://tests/practice_ui.gd'])
run([engine,'--headless','--path','.','--quit-after','10'])
run(['git','diff','--check'])
print('PASS: pinned engine, import, editor, core/UI tests, failure exit, application boot, whitespace')
