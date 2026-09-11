# Validation

The package check uses Python 3.10+ and the standard library:

```sh
python tests/validate_release.py
python -m unittest discover -s tests -p "test_*.py" -v
```

On Windows, `tests/validate-release.ps1` forwards to the same Python validator.
Add `--require-clean-worktree` to the Python command (or
`-RequireCleanWorktree` to PowerShell) only when checking a finalized checkout.

The validator checks required files, the installable skill's name and description,
UTF-8 Markdown, common relative links and heading anchors, package boundaries, and
private machine paths in the installed content. It does not fetch remote URLs or
prove that an agent follows the skill. It supports the simple scalar frontmatter,
inline/reference links, HTML links, and headings used in this repository, not
every YAML or CommonMark construct. Metadata outside name/description is not
schema-validated. Use forward slashes and percent-encode parentheses in local URLs.

The mutation tests exercise real packaging failures rather than require fixed
sentences in the skill. A symlink escape test may be skipped on Windows accounts
without permission to create symlinks.

## Behavioral scenarios

Eight [scenario definitions](scenarios/) share three small Python
[fixture projects](fixtures/). The definitions contain raw starting state and the
user's request; expected behavior lives separately in the
[evaluator rubric](scenario-rubric.md). Fixture tests intentionally fail where the
scenario begins with a bug. They are not release-validator failures.

Use Git and Python to prepare a fresh isolated directory:

```sh
python tests/prepare_scenario.py staged-user-edit /path/to/empty/run
```

The destination must be new or empty. The script creates a local Git baseline,
applies any staged user edit and unstaged change, and prints the user prompt. It
sets that repository's hooks path to an empty directory inside its `.git` folder,
so fixture commits do not run the user's configured Git hooks. It
does not install a skill, launch an agent, contact a service, or score the result.
All eight IDs are the JSON filenames without the extension in `tests/scenarios`.

Give an acting agent only the prepared repository and prompt, with the assigned
skill condition loaded by its host. Do not give it this README, the other
scenarios, or the rubric. Preserve its transcript and diff for a separate
evaluation. Compare previous-release, candidate, and no-ADD runs under equivalent
conditions. Report unrun scenarios as unrun; structure checks are not behavioral
evidence. See the [validation report](../docs/validation-report.md) for observations
from this refactor.
