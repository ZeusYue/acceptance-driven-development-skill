# Install ADD with CC Switch

This guide installs ADD from the official repository through [CC Switch](https://github.com/farion1231/cc-switch). It complements the short installation section in the [main README](../README.md).

## Before you start

- Install CC Switch and make sure the agent application you want to configure is available in CC Switch.
- ADD has two skill folders. Install both:
  - `acceptance-driven-development`
  - `project-experience`
- This repository already has the CC Switch-friendly layout: the installable skills are under `skills/`. Do not point CC Switch at an individual `SKILL.md` file.

## Add the repository

1. In CC Switch, select the target agent application.
2. Open **Skills**.
3. Choose **Repository Management**.
4. Choose **Add Repository** (or the equivalent custom-repository action in your CC Switch version).
5. Enter exactly:

   - Owner: `ZeusYue`
   - Name: `acceptance-driven-development-skill`
   - Branch: `main`
   - Subdirectory: `skills`

6. Save, then refresh the repository list.

## Install the skills

1. Find `acceptance-driven-development` in the repository list and choose **Install**.
2. Find `project-experience` and choose **Install**.
3. Restart the selected agent application or begin a new session so it discovers the installed skills.

CC Switch installs skills into the target application’s configured skills directory. You normally do not need to copy files manually after a successful install.

## Verify the installation

Use the target agent and send a request such as:

```text
Use acceptance-driven-development to implement a small feature.
```

A correct ADD run announces **Phase 0 — Locating document hub**. For existing approved AC rows it later announces **Phase 3.5A**; for a new mid-project change it announces **Phase 3.5B**.

If the agent cannot discover the skill:

1. Confirm that the repository configuration uses `skills`, not `skills/acceptance-driven-development`.
2. Refresh the repository list in CC Switch.
3. Confirm both skills show as installed for the selected agent application.
4. Restart the agent application and start a new session.
5. If the host uses a custom skills directory, follow that host’s documented directory instead and use the manual installation instructions in the main README.

## Update to a newer ADD release

1. Open **Skills** in CC Switch.
2. Refresh the repository list.
3. Use **Update** for each installed ADD skill, or **Update All** if you want to update all installed skills.
4. Restart the target agent session.

When updating to v2.0, update both ADD skills together. Existing `AC.md` files remain valid; read [Migrating to v2.0](../README.md#migrating-to-v20) before the first cache refresh.

## Remove ADD

Use CC Switch’s uninstall action for both skills. This removes the installed skill copies only. It does **not** delete your `$DOC_HUB`, `AC.md` files, project documents, or `~/.add-hub` pointer.

## Manual fallback

If CC Switch cannot manage your host, copy both skill directories manually as described in the [main README](../README.md#option-2--manual-installation).
