# SPDX-License-Identifier: Apache-2.0
import contextlib
import io
from pathlib import Path
import subprocess
import sys
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
import verify


class VerificationTests(unittest.TestCase):
    def plan(self, *names):
        return verify.build_plan(verify.select_suites(names), 'test-godot')

    def scripts(self, plan):
        return [check.command[check.command.index('--script') + 1]
                for check in plan if '--script' in check.command and not check.failure]

    def test_default_retains_algorithms_and_boot_without_heavy_suites(self):
        output = io.StringIO()
        with patch.object(verify, 'run') as run, contextlib.redirect_stdout(output):
            verify.main([])
        plan = [call.args[0] for call in run.call_args_list]
        self.assertEqual(self.scripts(plan), ['res://tests/run_all.gd'])
        self.assertTrue(any(check.failure for check in plan))
        self.assertTrue(any('--quit-after' in check.command for check in plan))
        self.assertTrue(any('unittest' in check.command for check in plan))
        self.assertTrue(any(check.command[0] == 'node' for check in plan))
        self.assertNotIn('Generate WAV fixtures', [check.name for check in plan])
        self.assertNotIn('Editor startup', [check.name for check in plan])
        self.assertIn('PASS: selected suites python, web, core, smoke', output.getvalue())

    def test_extended_keeps_all_headless_regressions_and_ci_audits_are_opt_in(self):
        manual = {'native_smoke.gd', 'hover_render.gd', 'menu_render.gd',
                  'presentation_render.gd', 'print_render.gd'}
        expected = {f'res://tests/{path.name}' for path in (ROOT / 'tests').glob('*.gd')
                    if path.name not in manual}
        plan = self.plan('extended')
        self.assertEqual(set(self.scripts(plan)), expected)
        self.assertEqual(len(self.scripts(plan)), len(expected))
        self.assertIn('Editor startup', [check.name for check in plan])
        state = [check for check in plan if check.name == 'local_state']
        self.assertEqual(len(state), 1)
        self.assertEqual(state[0].command[-2:], ('--', '--extended'))
        for workflow in ('verify.yml', 'release.yml'):
            text = (ROOT / '.github/workflows' / workflow).read_text()
            self.assertIn('python3 scripts/verify.py --full', text)
            self.assertNotRegex(text, r'(?m)^\s*(?:run:\s*)?python3 scripts/verify\.py\s*$')
        workflow = (ROOT / '.github/workflows/verify.yml').read_text()
        self.assertIn("if: github.event_name == 'workflow_dispatch' && inputs.extended", workflow)
        self.assertIn('default: false', workflow)

    def test_standard_gate_retains_representative_ui_and_state_without_optional_matrices(self):
        plan = self.plan('full')
        scripts = set(self.scripts(plan))
        self.assertTrue({'res://tests/ui_smoke.gd', 'res://tests/local_state.gd',
                         'res://tests/practice_navigation.gd', 'res://tests/live_input.gd'} <= scripts)
        for name in ('practice_ui', 'layout_ui', 'interface_ui', 'theater_ui', 'menu_navigation'):
            self.assertNotIn(f'res://tests/{name}.gd', scripts)
        self.assertNotIn('Editor startup', [check.name for check in plan])
        self.assertFalse(any('--extended' in check.command for check in plan))
        audits = set(self.scripts(self.plan('ui-audit')))
        self.assertTrue({'res://tests/practice_ui.gd', 'res://tests/layout_ui.gd',
                         'res://tests/interface_ui.gd', 'res://tests/theater_ui.gd',
                         'res://tests/menu_navigation.gd', 'res://tests/local_state.gd'} <= audits)

    def test_combined_suites_share_prerequisites_and_prepare_wavs_before_replay(self):
        plan = self.plan('input', 'ui', 'practice', 'input')
        names = [check.name for check in plan]
        self.assertEqual(names.count('Pinned engine'), 1)
        self.assertEqual(names.count('Project import'), 1)
        self.assertEqual(names.count('Generate WAV fixtures'), 1)
        self.assertEqual(names.count('practice_navigation'), 1)
        self.assertEqual(names.count('ui_smoke'), 1)
        self.assertLess(names.index('Generate WAV fixtures'), names.index('Project import'))
        self.assertLess(names.index('Project import'), names.index('microphone_fixtures'))
        self.assertEqual(names[-1], 'Whitespace')

    def test_web_and_python_can_run_without_godot_and_listing_launches_nothing(self):
        plan = self.plan('python', 'web')
        self.assertFalse(any(check.command[0] == 'test-godot' for check in plan))
        output = io.StringIO()
        with patch.object(verify.subprocess, 'run') as run, contextlib.redirect_stdout(output):
            verify.main(['--suite', 'menu', '--list'])
        run.assert_not_called()
        self.assertIn('res://tests/menu_navigation.gd', output.getvalue())
        self.assertNotIn('res://tests/practice_ui.gd', output.getvalue())
        self.assertNotIn('PASS:', output.getvalue())

    def result(self, code, output, *, failure=False, version=''):
        check = verify.Check('fixture', ('test-godot',), failure=failure, expected_version=version)
        with patch.object(verify.subprocess, 'run', return_value=subprocess.CompletedProcess(
                [], code, output)), contextlib.redirect_stdout(io.StringIO()):
            verify.run(check)

    def test_failures_include_zero_exit_godot_errors_and_exact_engine_mismatch(self):
        for code, output in ((1, ''), (0, 'SCRIPT ERROR: broken'), (0, 'ERROR: broken'),
                             (0, 'WARNING: leaked'), (0, 'Unicode parsing error'), (0, 'FAIL: test')):
            with self.subTest(code=code, output=output), self.assertRaises(SystemExit):
                self.result(code, output)
        with self.assertRaisesRegex(SystemExit, 'Expected pinned; found other'):
            self.result(0, 'other\n', version='pinned')
        self.result(0, 'pinned\n', version='pinned')
        self.result(0, 'all checks passed\n')

    def test_intentional_failure_requires_both_signal_and_nonzero_exit(self):
        marker = 'FAIL: intentional test-runner failure\n'
        self.result(1, marker, failure=True)
        for code, output in ((0, marker), (1, 'unrelated failure'),
                             (1, marker + 'SCRIPT ERROR: unrelated')):
            with self.subTest(code=code, output=output), self.assertRaises(SystemExit):
                self.result(code, output, failure=True)

    def test_timeout_and_missing_prerequisite_are_actionable_failures(self):
        for error, message in ((subprocess.TimeoutExpired('test-godot', 120, output=b'partial log'),
                                'Verification timed out'), (FileNotFoundError('missing'), 'Cannot run')):
            with self.subTest(error=error), patch.object(verify.subprocess, 'run', side_effect=error), \
                    contextlib.redirect_stdout(io.StringIO()), self.assertRaisesRegex(SystemExit, message):
                verify.run(verify.Check('fixture', ('test-godot',)))


if __name__ == '__main__':
    unittest.main()
