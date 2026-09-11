"""Check that evaluation fixtures are reproducible and preserve Git distinctions."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

from prepare_scenario import TESTS, prepare, write_files


@unittest.skipUnless(shutil.which("git"), "scenario setup requires Git")
class ScenarioPreparationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(ignore_cleanup_errors=True)
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)

    def git(self, root, *arguments):
        return subprocess.run(["git", "-C", str(root), *arguments], capture_output=True, text=True, check=True).stdout

    def test_all_scenarios_have_executable_starting_state(self):
        for definition in sorted((TESTS / "scenarios").glob("*.json")):
            with self.subTest(scenario=definition.stem):
                destination = self.root / definition.stem
                prompt = prepare(definition.stem, destination)
                self.assertTrue(prompt.strip())
                check = subprocess.run([sys.executable, "-m", "unittest", "-v"], cwd=destination, capture_output=True, text=True)
                if definition.stem == "product-boundary":
                    self.assertEqual(0, check.returncode, check.stderr)
                else:
                    self.assertEqual(1, check.returncode, check.stderr)
                    self.assertIn("FAILED (failures=", check.stderr)
                    self.assertNotIn("errors=", check.stderr)

    def test_staged_user_change_is_separate_from_baseline(self):
        destination = self.root / "staged"
        prepare("staged-user-edit", destination)
        staged = self.git(destination, "diff", "--cached", "--", "exporter.py")
        self.assertIn("Product wording approved by the user", staged)
        self.assertEqual("", self.git(destination, "diff", "--", "exporter.py"))
        self.assertNotIn("Product wording approved by the user", self.git(destination, "show", "HEAD:exporter.py"))

    def test_config_change_is_unstaged(self):
        destination = self.root / "configuration"
        prepare("stale-config-evidence", destination)
        self.assertEqual("", self.git(destination, "diff", "--cached"))
        self.assertIn('"default_limit": 20', self.git(destination, "diff", "--", "config.json"))

    def test_nonempty_destination_is_not_overwritten(self):
        protected = self.root / "user.txt"
        protected.write_text("user work", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "new or empty"):
            prepare("small-fix", self.root)
        self.assertEqual("user work", protected.read_text(encoding="utf-8"))
        self.assertFalse((self.root / ".git").exists())

    def test_preparation_disables_global_hooks(self):
        hooks = self.root / "global-hooks"
        hooks.mkdir()
        hook = hooks / "pre-commit"
        hook.write_text('#!/bin/sh\nprintf invoked > "$ADD_TEST_HOOK_SENTINEL"\nexit 73\n', encoding="utf-8", newline="\n")
        hook.chmod(0o755)
        sentinel = self.root / "hook-ran.txt"
        global_config = self.root / "global.gitconfig"
        global_config.write_text(f"[core]\n\thooksPath = {json.dumps(hooks.as_posix())}\n", encoding="utf-8")
        environment = {
            "GIT_CONFIG_GLOBAL": str(global_config),
            "GIT_CONFIG_NOSYSTEM": "1",
            "ADD_TEST_HOOK_SENTINEL": sentinel.as_posix(),
        }
        destination = self.root / "fixture"
        with patch.dict(os.environ, environment):
            prepare("small-fix", destination)
            self.assertFalse(sentinel.exists(), "fixture creation executed a user hook")
            disabled = destination / ".git" / "disabled-hooks"
            self.assertTrue(disabled.is_dir())
            self.assertEqual([], list(disabled.iterdir()))
            self.assertEqual(disabled.as_posix(), self.git(destination, "config", "--local", "core.hooksPath").strip())

            # Positive control: the same hook really executes when the override is removed.
            self.git(destination, "config", "--local", "--unset", "core.hooksPath")
            with self.assertRaises(subprocess.CalledProcessError):
                self.git(destination, "-c", "user.name=ADD Fixture", "-c", "user.email=fixture@example.invalid", "-c", "commit.gpgsign=false", "commit", "--allow-empty", "-m", "Hook positive control")
            self.assertEqual("invoked", sentinel.read_text(encoding="utf-8"))

    def test_fixture_paths_cannot_escape_or_write_git_metadata(self):
        for relative in ("../outside.txt", ".git/config", ".GIT/config", "nested/.Git/config"):
            with self.subTest(path=relative), self.assertRaisesRegex(ValueError, "invalid fixture path"):
                write_files(self.root, {relative: "bad"})


if __name__ == "__main__":
    unittest.main()
