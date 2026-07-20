# Install ADD with CC Switch

Use this guide after you understand what ADD does from the [main README](../README.md). CC Switch can recursively discover both skills in this repository; a temporary zero count can also mean that GitHub archive download or refresh failed.

## Add the repository

1. Select the target agent application.
2. Open **Skills → Discover Skills → Repository Management → Add Skill Repository**.
3. Enter:

   ```text
   Repository URL: https://github.com/ZeusYue/acceptance-driven-development-skill
   Branch: main
   ```

4. Save the repository record.
5. Return to **Discover Skills** and refresh.

The discoverable files are:

```text
skills/acceptance-driven-development/SKILL.md
skills/project-experience/SKILL.md
```

Install both skills, then begin a new target-agent session.

## If discovery shows 0 skills

1. Confirm the repository URL ends at `acceptance-driven-development-skill`.
2. Confirm the branch is exactly `main`.
3. Refresh Discover Skills and restart CC Switch if necessary.
4. If the repository record cannot be corrected, delete and add it again.

### GitHub archive, network, and proxy

CC Switch downloads the GitHub archive for the selected branch before it scans `SKILL.md`. Verify that the same archive is reachable in a browser:

```text
https://github.com/ZeusYue/acceptance-driven-development-skill/archive/refs/heads/main.zip
```

If it cannot download:

- change network, or configure the system / CC Switch network proxy for your environment;
- restart CC Switch after changing network or proxy settings;
- refresh Discover Skills again.

If the archive downloads successfully but CC Switch still reports zero skills, the repository layout is not the first suspect: the current archive contains two valid `SKILL.md` files. Use manual installation as a temporary workaround and file an issue with the CC Switch version, screenshots, and whether the archive URL downloaded.

## Windows: Failed to create symbolic link

A message such as `Failed to create symbolic link: …` is a local installation permission or storage-location problem, not a repository-discovery problem.

1. Open CC Switch **Settings** and set the skills storage location to `~/.agents/skills`.
2. If CC Switch offers a skill sync method, choose **Copy** rather than a symbolic-link method.
3. Restart CC Switch, refresh **Discover Skills**, and install both skills again.
4. If you must use symbolic links, run CC Switch as Administrator or enable Windows Developer Mode, then retry.

Changing the storage location or sync method may require reinstalling the skills for the selected target agent.

## Update or remove

Refresh discovery, then update both ADD skills. Uninstalling them does not delete your `$DOC_HUB`, AC files, project documents, or `~/.add-hub` pointer.
