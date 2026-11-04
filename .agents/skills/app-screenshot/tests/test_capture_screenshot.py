"""CLI regression tests: no screen capture, process launch, or macOS permission required."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest

HELPER = Path(__file__).resolve().parents[1] / 'scripts/capture_screenshot.sh'


class CaptureCliTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='capture-cli-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.project = self.root / 'target project'
        self.project.mkdir()
        self.env = dict(os.environ)
        # A dry run must not observe or launch real processes, even with --launch.
        bin_dir = self.root / 'bin'
        bin_dir.mkdir()
        pgrep = bin_dir / 'pgrep'
        pgrep.write_text('#!/bin/sh\nprintf called > "$PGREP_MARKER"\nexit 0\n')
        pgrep.chmod(0o755)
        self.marker = self.root / 'pgrep-called'
        self.env.update(PATH=f'{bin_dir}{os.pathsep}{self.env["PATH"]}', PGREP_MARKER=str(self.marker))

    def run_helper(self, *args, ready=True):
        command = [str(HELPER), '--project-root', str(self.project), '--dry-run']
        if ready:
            command += ['--ready-pattern', 'example-process']
        return subprocess.run(command + list(args), cwd=self.root, env=self.env,
                              capture_output=True, text=True, timeout=5, check=False)

    def test_relocated_helper_uses_the_target_project_and_creates_nothing(self):
        result = self.run_helper('--run', 'smoke', '--name', 'window')

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(str(self.project / 'artifacts/screenshots/smoke/window.png'), result.stdout)
        self.assertEqual(list(self.project.iterdir()), [])
        self.assertFalse(self.marker.exists())

    def test_current_directory_is_the_default_project(self):
        result = subprocess.run([str(HELPER), '--dry-run', '--ready-pattern', 'example-process', '--name', 'view'],
                                cwd=self.project, env=self.env, capture_output=True,
                                text=True, timeout=5, check=False)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(str(self.project / 'artifacts/screenshots/view.png'), result.stdout)
        self.assertEqual(list(self.project.iterdir()), [])

    def test_window_owner_can_supply_readiness(self):
        result = self.run_helper('--window-process', '^ExampleApp$', ready=False)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('Would wait for readiness pattern: ^ExampleApp$', result.stdout)
        self.assertIn('Would resolve a window for process pattern: ^ExampleApp$', result.stdout)

    def test_missing_target_fails_without_an_app_specific_default(self):
        result = self.run_helper(ready=False)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn('--ready-pattern or --window-process is required', result.stderr)

    def test_capture_selectors_and_custom_artifact_root(self):
        for selector, argument in ((['--window-id', '123'], '-l 123'),
                                   (['--window'], '-w'), (['--display', '2'], '-D 2')):
            with self.subTest(selector=selector):
                result = self.run_helper('--artifact-root', 'evidence', '--name', 'view', *selector)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn(argument, result.stdout)
                self.assertIn(str(self.project / 'evidence/screenshots/view.png'), result.stdout)
        self.assertEqual(list(self.project.iterdir()), [])

    def test_invalid_combinations_and_values_fail(self):
        cases = [
            (['--window-id', '123', '--window'], 'choose only one'),
            (['--window-process', 'app', '--display', '2'], '--display cannot'),
            (['--name', '../escape'], 'invalid --name'),
            (['--run', '../escape'], 'invalid --run'),
            (['--repeat', '0'], '--repeat must'),
            (['--window-id', '0'], '--window-id must'),
            (['--keep-running'], '--keep-running is valid only with --launch'),
            (['--launch'], '--launch requires a command'),
            (['--', 'example-app'], 'requires explicit --launch'),
        ]
        for args, error in cases:
            with self.subTest(args=args):
                result = self.run_helper(*args)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(error, result.stderr)
        self.assertEqual(list(self.project.iterdir()), [])

    def test_output_cannot_escape_the_artifact_root(self):
        for path in ('../outside', 'artifacts/../outside', str(self.root / 'outside')):
            with self.subTest(path=path):
                result = self.run_helper('--output-dir', path)
                self.assertNotEqual(result.returncode, 0)
        self.assertEqual(list(self.project.iterdir()), [])

    def test_existing_symlink_cannot_escape_the_artifact_root(self):
        artifacts = self.project / 'artifacts'
        artifacts.mkdir()
        (artifacts / 'escape').symlink_to(self.root, target_is_directory=True)

        result = self.run_helper('--output-dir', 'artifacts/escape/new-directory')

        self.assertNotEqual(result.returncode, 0)
        self.assertIn('--output-dir must be inside', result.stderr)
        self.assertFalse((self.root / 'new-directory').exists())

    def test_run_directory_symlink_cannot_escape_the_artifact_root(self):
        output = self.project / 'artifacts/screenshots'
        output.mkdir(parents=True)
        (output / 'escape').symlink_to(self.root, target_is_directory=True)

        result = self.run_helper('--run', 'escape')

        self.assertNotEqual(result.returncode, 0)
        self.assertIn('--output-dir must be inside', result.stderr)

    def test_overwrite_cannot_follow_a_screenshot_symlink(self):
        output = self.project / 'artifacts/screenshots'
        output.mkdir(parents=True)
        target = self.root / 'outside.png'
        target.write_bytes(b'original-image')
        (output / 'view.png').symlink_to(target)

        result = self.run_helper('--name', 'view', '--overwrite')

        self.assertNotEqual(result.returncode, 0)
        self.assertIn('refuse to overwrite a screenshot symlink', result.stderr)
        self.assertEqual(target.read_bytes(), b'original-image')

    def test_existing_images_are_preserved_unless_overwrite_is_requested(self):
        output = self.project / 'artifacts/screenshots'
        output.mkdir(parents=True)
        existing = output / 'view.png'
        existing.write_bytes(b'original-image')

        unique = self.run_helper('--name', 'view')
        overwrite = self.run_helper('--name', 'view', '--overwrite')

        self.assertEqual(unique.returncode, 0, unique.stderr)
        self.assertIn(str(output / 'view-01.png'), unique.stdout)
        self.assertEqual(overwrite.returncode, 0, overwrite.stderr)
        self.assertIn(str(existing), overwrite.stdout)
        self.assertEqual(existing.read_bytes(), b'original-image')
        self.assertEqual(list(output.iterdir()), [existing])

    def test_dry_run_does_not_launch_poll_or_sleep_for_repeat_intervals(self):
        marker = self.root / 'must-not-launch'

        result = self.run_helper('--repeat', '3', '--interval-secs', '60', '--name', 'view',
                                 '--launch', '--', '/usr/bin/touch', str(marker))

        self.assertEqual(result.returncode, 0, result.stderr)
        for index in range(1, 4):
            self.assertIn(str(self.project / f'artifacts/screenshots/view-{index:02d}.png'), result.stdout)
        self.assertFalse(marker.exists())
        self.assertFalse(self.marker.exists())
        self.assertEqual(list(self.project.iterdir()), [])

    def test_trailing_separator_in_artifact_root_is_supported(self):
        result = self.run_helper('--artifact-root', 'evidence/', '--name', 'view')

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(str(self.project / 'evidence/screenshots/view.png'), result.stdout)


if __name__ == '__main__':
    unittest.main()
