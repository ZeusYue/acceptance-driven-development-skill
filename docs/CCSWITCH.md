# Install ADD with CC Switch

This guide uses the standard CC Switch flow that adds a skill repository through a repository URL and a branch.

## Before you begin

- Use the repository root, not an individual `SKILL.md` URL.
- The branch is exactly `main`.
- The repository already exposes discoverable skills at:

  ```text
  skills/acceptance-driven-development/SKILL.md
  skills/project-experience/SKILL.md
  ```

- Install both skills after discovery.

## Add the repository

1. Select the agent application you want to configure.
2. Open **Skills → Discover Skills → Repository Management → Add Skill Repository**.
3. Enter:

   ```text
   Repository URL: https://github.com/ZeusYue/acceptance-driven-development-skill
   Branch: main
   ```

4. Save the repository record.
5. Return to **Discover Skills** and refresh the scan if the list does not update immediately.

## Install and verify

1. Install `acceptance-driven-development`.
2. Install `project-experience`.
3. Start a new target-agent session.
4. Ask:

   ```text
   Use ADD to implement a small feature.
   ```

A correct run announces Phase 0. Existing approved backlog work later announces Phase 3.5A; a new mid-project change announces Phase 3.5B.

## If CC Switch finds 0 skills

Check these in order:

1. Confirm the saved branch is `main`, character for character.
2. Confirm the repository URL ends at `acceptance-driven-development-skill`, not at a file or `tree/...` page.
3. Refresh Discover Skills after adding the repository.
4. If the saved branch cannot be changed, delete the repository record and add it again with `main`.
5. Restart CC Switch and the target agent after a successful install.
6. Only investigate repository layout after the URL and branch have been confirmed.

## Update or remove

Refresh the repository scan, then use the update action for both ADD skills. Uninstalling the skills does not delete your `$DOC_HUB`, AC files, project documents, or `~/.add-hub` pointer.

For manual installation paths, see the [main README](../README.md#option-2--manual-installation).
