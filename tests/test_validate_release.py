"""Mutation tests for release structure, deliberately independent of ADD wording."""

from pathlib import Path
import tempfile
import unittest

from validate_release import REQUIRED_FILES, SKILL_NAME, SKILL_PATH, validate


class ReleaseValidationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        for path in REQUIRED_FILES:
            self.write(path, "# Document\n")
        self.skill = SKILL_PATH / "SKILL.md"
        self.write(self.skill, f"---\nname: {SKILL_NAME}\ndescription: Use when changing a persistent software project.\n---\n# ADD\n")

    def write(self, relative, content):
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")

    def append(self, relative, content):
        path = self.root / relative
        path.write_text(path.read_text(encoding="utf-8") + content, encoding="utf-8")

    def assert_invalid(self, message):
        errors = validate(self.root)
        self.assertTrue(any(message in error for error in errors), errors)

    def test_minimal_public_package_is_valid(self):
        self.assertEqual([], validate(self.root))

    def test_each_required_file_is_required(self):
        for relative in REQUIRED_FILES:
            with self.subTest(path=relative):
                path = self.root / relative
                content = path.read_text(encoding="utf-8")
                path.unlink()
                self.assert_invalid(f"missing required file: {relative.as_posix()}")
                self.write(relative, content)

    def test_bad_frontmatter(self):
        cases = (
            ("# ADD\n", "must begin with YAML"),
            ("---\nname: acceptance-driven-development\n", "no closing delimiter"),
            ("---\nname acceptance-driven-development\n---\n", "invalid top-level"),
            ("---\nname: acceptance-driven-development\nname: other\ndescription: Valid text\n---\n", "duplicate frontmatter key"),
            ("---\nname: other\ndescription: Valid text\n---\n", "name must match"),
            ("---\nname: acceptance-driven-development\ndescription:\n---\n", "nonempty single-line"),
            ("---\nname: acceptance-driven-development\ndescription: []\n---\n", "must be a string"),
            ("---\nname: acceptance-driven-development\ndescription: 123\n---\n", "must be a string"),
            ("---\nname: acceptance-driven-development\ndescription: \"unclosed\n---\n", "invalid quoted"),
        )
        for content, error in cases:
            with self.subTest(error=error):
                self.write(self.skill, content)
                self.assert_invalid(error)

    def test_quoted_description_and_optional_metadata(self):
        self.write(self.skill, f'---\nname: {SKILL_NAME}\ndescription: "Use when: changing a project."\nmetadata:\n  short-description: ADD\n---\n# ADD\n')
        self.assertEqual([], validate(self.root))

    def test_skill_directory_name_and_removed_companion(self):
        (self.root / SKILL_PATH).rename(self.root / "skills/Wrong_Name")
        self.assert_invalid("unexpected skill directory: Wrong_Name")
        self.assert_invalid("missing required file: skills/acceptance-driven-development/SKILL.md")

    def test_missing_relative_link(self):
        self.append("README.md", "[guide](docs/missing.md)\n")
        self.assert_invalid("broken relative link: docs/missing.md")

    def test_code_formatted_link_label_is_still_checked(self):
        self.append("README.md", "[`SKILL.md`](missing/SKILL.md)\n")
        self.assert_invalid("broken relative link: missing/SKILL.md")

    def test_unicode_encoded_spaces_and_duplicate_heading_anchors(self):
        self.write("docs/A guide.md", "# Getting started\n## Details\n## Details\n## 中文验证\n")
        self.append("README.md", "[start](docs/A%20guide.md#getting-started)\n[duplicate](<docs/A guide.md#details-1>)\n[中文](docs/A%20guide.md#%E4%B8%AD%E6%96%87%E9%AA%8C%E8%AF%81)\n")
        self.assertEqual([], validate(self.root))

    def test_missing_heading_in_existing_file(self):
        self.append("README.md", "[bad anchor](README-zh.md#not-present)\n")
        self.assert_invalid("missing heading anchor")

    def test_local_anchor_and_html_anchor(self):
        self.append("README.md", '<a id="custom"></a>\n[local](#document)\n<a href="#custom">HTML</a>\n')
        self.assertEqual([], validate(self.root))

    def test_reference_links_and_missing_reference(self):
        self.append("README.md", "[translation][zh]\n[zh]: README-zh.md#document\n")
        self.assertEqual([], validate(self.root))
        self.append("README.md", "[bad][undefined]\n")
        self.assert_invalid("undefined Markdown reference")

    def test_fenced_and_inline_examples_are_not_links(self):
        self.append("README.md", "```md\n[example](does-not-exist)\n```\n`[example](missing)`\n<!-- [old](missing) -->\n")
        self.assertEqual([], validate(self.root))

    def test_external_urls_are_not_fetched(self):
        self.append("README.md", "[online](https://invalid.example/no-file#missing)\n[email](mailto:someone@example.com)\n")
        self.assertEqual([], validate(self.root))

    def test_release_link_cannot_escape_root(self):
        self.append("README.md", "[outside](../outside.md)\n")
        self.assert_invalid("link escapes package boundary")

    def test_installed_skill_cannot_depend_on_release_readme(self):
        self.append(self.skill, "[release docs](../../README.md)\n")
        self.assert_invalid("link escapes package boundary")

    def test_absolute_filesystem_links_are_not_portable(self):
        for target in ("C:/docs/guide.md", "/tmp/guide.md", "file:///tmp/guide.md"):
            with self.subTest(target=target):
                self.write("README.md", f"[guide]({target})\n")
                self.assertTrue(validate(self.root))

    def test_private_paths_are_rejected_only_in_installable_content(self):
        for target in (r"C:\Users\Example\docs", "/home/alice/docs", "/Users/alice/docs", r"\\office\share\docs"):
            with self.subTest(target=target):
                self.write(SKILL_PATH / "references/design-decisions.md", f"Open `{target}`.\n")
                self.assert_invalid("private machine-specific")

    def test_symlink_cannot_escape_package(self):
        external = self.root.parent / (self.root.name + "-external.md")
        external.write_text("# External\n", encoding="utf-8")
        self.addCleanup(lambda: external.unlink(missing_ok=True))
        linked = self.root / SKILL_PATH / "external.md"
        try:
            linked.symlink_to(external)
        except OSError:
            self.skipTest("symlink creation is unavailable for this account")
        self.append(self.skill, "[external](external.md)\n")
        self.assert_invalid("outside its package")
        self.assert_invalid("link escapes package boundary")

    def test_invalid_utf8_reports_an_issue(self):
        (self.root / self.skill).write_bytes(b"\xff")
        self.assert_invalid("cannot read UTF-8")


if __name__ == "__main__":
    unittest.main()
