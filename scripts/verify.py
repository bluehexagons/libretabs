#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Run quick checks, the standard CI/release gate, or optional extended audits."""
import argparse
from dataclasses import dataclass
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
COMMAND_TIMEOUT_SECONDS = 120
ERROR_PATTERN = re.compile(r'(SCRIPT ERROR:|^ERROR:|^WARNING:|Unicode parsing error|FAIL:)', re.M)
SUITES = {
    'python': 'Python tooling, release, site and library unit tests',
    'web': 'Browser bridge and service-worker JavaScript unit tests',
    'editor': 'Optional extended editor startup/scan audit',
    'core': 'MIDI, song, notation, transport and settings algorithms; failure self-test',
    'input': 'Keyboard/MIDI integration, pitch/tuner, WAV replay and sound commands',
    'audio': 'Synth rendering, part mixing and audio effects',
    'ui-smoke': 'Representative wide/narrow layout, menu, playback and input regressions',
    'practice': 'Navigation and animated page-following regressions',
    'practice-audit': 'Optional broad practice-control and presentation audit',
    'layout': 'Optional responsive score, interface and Theater matrices',
    'menu': 'Optional menu, search, appearance and localization audit',
    'state': 'Local settings/progress persistence and recovery',
    'state-audit': 'Optional state recovery plus interface/viewport/text-size matrix',
    'smoke': 'Application boot',
}
PROFILES = {
    'quick': ('python', 'web', 'core', 'smoke'),
    'ui': ('ui-smoke', 'practice', 'state'),
    'ui-audit': ('practice-audit', 'layout', 'menu', 'state-audit'),
    'full': ('python', 'web', 'core', 'input', 'audio', 'ui-smoke', 'practice', 'state', 'smoke'),
    'extended': tuple(SUITES),
}


@dataclass(frozen=True)
class Check:
    name: str
    command: tuple[str, ...]
    failure: bool = False
    expected_version: str = ''


def select_suites(names):
    requested = set()
    for name in names:
        if name not in SUITES and name not in PROFILES:
            raise ValueError(f'Unknown verification suite: {name}')
        requested.update(PROFILES.get(name, (name,)))
    return tuple(name for name in SUITES if name in requested)


def build_plan(suites, engine):
    godot = (engine, '--headless', '--path', '.')

    def script(name, *user_args):
        suffix = ('--', *user_args) if user_args else ()
        return Check(name, (*godot, '--script', f'res://tests/{name}.gd', *suffix))

    commands = {
        'python': [Check('Python tests', ('python3', '-m', 'unittest', 'discover', '-s', 'tests', '-p', 'test_*.py'))],
        'web': [Check('JavaScript tests', ('node', '--test', 'tests/service_worker.test.mjs',
                                         'tests/playing_bridge.test.mjs', 'tests/host_bridge.test.mjs'))],
        'editor': [Check('Editor startup', (*godot, '--editor', '--quit-after', '60'))],
        'core': [script('run_all'), Check('Failure self-test', (*godot, '--script',
                 'res://tests/run_all.gd', '--', '--self-test-failure'), failure=True)],
        'input': [script(name) for name in ('live_input', 'pitch_detection', 'tuner_response',
                                          'microphone_fixtures', 'audio_commands')],
        'audio': [script(name) for name in ('synth_audio', 'part_audio', 'audio_effects')],
        'ui-smoke': [script('ui_smoke')],
        'practice': [script(name) for name in ('practice_navigation', 'page_follow_ui')],
        'practice-audit': [script('practice_ui')],
        'layout': [script(name) for name in ('layout_ui', 'interface_ui', 'theater_ui')],
        'menu': [script('menu_navigation')],
        'state': [script('local_state')],
        'state-audit': [script('local_state', '--extended')],
        'smoke': [Check('Application boot', (*godot, '--quit-after', '10'))],
    }
    plan = []
    needs_engine = any(name not in ('python', 'web') for name in suites)
    if needs_engine:
        version = json.loads((ROOT / 'release/toolchain.json').read_text())['version']
        plan.append(Check('Pinned engine', (engine, '--version'), expected_version=version))
    prepared = False
    for name in suites:
        if name == 'state' and 'state-audit' in suites:
            continue  # The extended state run includes every standard state case.
        if name not in ('python', 'web') and not prepared:
            if 'input' in suites:
                plan.append(Check('Generate WAV fixtures', ('python3', 'scripts/generate_audio_fixtures.py')))
            plan.append(Check('Project import', (*godot, '--import')))
            prepared = True
        plan.extend(commands[name])
    plan.append(Check('Whitespace', ('git', 'diff', '--check')))
    return plan


def run(check):
    print(f'RUN: {check.name}', flush=True)
    started = time.monotonic()
    try:
        result = subprocess.run(check.command, cwd=ROOT, text=True, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, timeout=COMMAND_TIMEOUT_SECONDS)
    except subprocess.TimeoutExpired as error:
        output = error.stdout or ''
        if isinstance(output, bytes):
            output = output.decode(errors='replace')
        print(output)
        raise SystemExit(f'Verification timed out after {COMMAND_TIMEOUT_SECONDS}s: {check.name}') from error
    except OSError as error:
        raise SystemExit(f'Cannot run {check.name}: {error}') from error
    if result.stdout:
        print(result.stdout, end='' if result.stdout.endswith('\n') else '\n', flush=True)
    output = result.stdout
    if check.expected_version:
        if result.returncode or output.strip() != check.expected_version:
            raise SystemExit(f'Expected {check.expected_version}; found {output.strip()}')
    elif check.failure:
        if result.returncode == 0 or 'FAIL: intentional test-runner failure' not in output:
            raise SystemExit('Test runner did not signal its deliberate failure')
        output = output.replace('FAIL: intentional test-runner failure', '')
        if ERROR_PATTERN.search(output):
            raise SystemExit(f'Unexpected error during {check.name}')
    elif result.returncode or ERROR_PATTERN.search(output):
        raise SystemExit(f'Verification failed: {check.name}')
    print(f'PASS: {check.name} ({time.monotonic() - started:.2f}s)', flush=True)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    selection = parser.add_mutually_exclusive_group()
    selection.add_argument('--suite', action='append', choices=(*PROFILES, *SUITES),
                           help='Run a named suite/profile; repeat to combine (default: quick)')
    selection.add_argument('--full', action='store_true', help='Run the standard CI/release gate')
    selection.add_argument('--extended', action='store_true', help='Also run optional broad UI/editor audits')
    parser.add_argument('--list', action='store_true', help='List suites and selected commands without running them')
    args = parser.parse_args(argv)
    profile = ['extended'] if args.extended else ['full'] if args.full else args.suite or ['quick']
    suites = select_suites(profile)
    plan = build_plan(suites, os.environ.get('GODOT', 'godot'))
    if args.list:
        for name, members in PROFILES.items():
            print(f'{name}: {", ".join(members)}')
        for name, description in SUITES.items():
            print(f'{name}: {description}')
        print('\nSelected commands:')
        for check in plan:
            print(f'  {check.name}: {shlex.join(check.command)}')
        return
    started = time.monotonic()
    print('Selected suites: ' + ', '.join(suites), flush=True)
    for check in plan:
        run(check)
    if suites == select_suites(['extended']):
        scope = 'extended verification including optional audits'
    elif suites == select_suites(['full']):
        scope = 'standard CI/release verification'
    else:
        scope = 'selected suites ' + ', '.join(suites)
    print(f'PASS: {scope} ({len(plan)} commands, {time.monotonic() - started:.2f}s)', flush=True)


if __name__ == '__main__':
    main()
