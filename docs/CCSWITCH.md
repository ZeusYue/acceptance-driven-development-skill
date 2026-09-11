# Installing ADD with CC Switch

These are optional installer notes. The [main README](../README.md#install) describes the portable installation contract. CC Switch labels and installation methods can vary by version; the current ADD revision has not been verified across all CC Switch or target-agent versions.

## Add the repository

In CC Switch, select the target agent, open its skill discovery or repository management screen, and add:

```text
Repository URL: https://github.com/ZeusYue/acceptance-driven-development-skill
Branch: main
Skill directory: skills/acceptance-driven-development
```

Refresh discovery and select `acceptance-driven-development`. This revision ships one skill, including its references and optional templates. Start or reload the target-agent session as that host requires.

The installer retrieves the selected remote branch. The public `v3.0.1` revision is available from `main`; future development snapshots may require manual installation of their local skill directory.

## If discovery shows no skills

Check the root repository URL and branch, then refresh discovery. Inspect any download or scan error your installer exposes. A zero count alone does not distinguish a network failure from a layout or installer problem.

If the installer uses GitHub branch archives, check whether the [main branch archive](https://github.com/ZeusYue/acceptance-driven-development-skill/archive/refs/heads/main.zip) is reachable in your environment. After fixing network or proxy settings, retry discovery. If discovery still fails, use the README's manual installation steps and report the installer version, exact error, and download result.

## Windows symbolic-link errors

Check the installation method, destination, and the exact error. Changing a storage location does not grant symbolic-link permission. Depending on the installer and Windows configuration, Developer Mode or an appropriate permission change may allow links; use your platform's guidance.

If the installer offers a copy method, that is also a valid installation option. Ensure the target agent discovers one intended copy of ADD, and update that copy when the skill changes.

## Updating

Replace or update the full installed ADD directory, including references and assets. Preserve local customizations separately before replacement and avoid retaining retired references in the active copy.

The former `project-experience` companion is outside the current package. Updating ADD does not remove a separately installed companion or any existing project records.
