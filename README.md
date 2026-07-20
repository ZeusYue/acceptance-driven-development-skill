# Acceptance-Driven Development (ADD) v2.1

<p align="center">
  <strong>Make coding agents prove that a change works — not merely claim that it is finished.</strong><br>
  ADD turns every meaningful change into an acceptance contract, an impact check, a review, and fresh evidence.
</p>

<p align="center">
  <a href="./README-zh.md">简体中文</a> ·
  <a href="#see-add-in-one-request">See it work</a> ·
  <a href="#install-add">Install</a> ·
  <a href="#cc-switch-shows-0-skills-found">Troubleshoot CC Switch</a>
</p>

---

## Why ADD changes agent development

Most agent workflows optimize for producing code quickly. ADD optimizes for **knowing when the work is actually safe to call done**.

| Without ADD | With ADD |
|---|---|
| “Implemented.” | “AC-12 passed `ctest`; here is the output.” |
| A small fix quietly breaks a working feature. | Impact analysis marks dependent criteria for fresh verification. |
| The agent remembers your architecture for a few messages. | Project documents and experience cache carry proven lessons forward. |
| A GUI feature is declared complete without anyone clicking it. | It remains `[!] [manual]` until someone verifies the exact interaction. |
| The same bug receives endless patches. | Three failures trigger diagnosis, redesign, guidance, or deferral. |

ADD is not a test framework and not a project manager. It is a **workflow contract** around your existing codebase, tests, tools, and judgment.

---

## See ADD in one request

Ask an agent:

```text
Add a bulk-delete action to the image browser. Use ADD.
```

A correct run should make its reasoning observable:

```text
Phase 3.5B — Impact analysis: bulk delete
→ Update the relevant acceptance criterion
→ Propose the approach and wait for approval
→ Phase 4 Mode B — implement 1 AC
→ Phase 4.8 — six-point review
→ Phase 5 — mark [!] [manual] with exact test steps
```

For an existing approved backlog, the agent instead announces **Phase 3.5A**, lists the target ACs, and enters Mode A without asking you to re-approve already approved requirements.

If you cannot see the phase announcement, the affected AC, the review result, or fresh verification evidence, you have a concrete question to ask — not a vague feeling that the agent skipped something.

---

## What ADD gives you

### An AC table that remains honest

`AC.md` is the acceptance source of truth.

| Mark | Meaning |
|---|---|
| `[ ]` | Not implemented |
| `[~]` | Partially implemented |
| `[x]` | Freshly verified passing |
| `[!] [manual]` | Implemented; needs hands-on verification |
| `[!] [affected]` | A prior pass was affected by another change; needs re-verification |
| `[!] [blocked]` | Verification is unavailable; reason and unblock condition recorded |
| `[>]` | Explicitly deferred |
| `[-]` | Explicitly deprecated |

### A document trail that survives the session

```text
$DOC_HUB/<ProjectName>/
├── AC.md                  # acceptance state
├── design.md              # greenfield design, when applicable
└── <ProjectName>.md       # living architecture and engineering record
```

ADD creates and updates the project document. `project-experience` reads it, finds relevant lessons, and later distills evidence-backed patterns into `_exp_memory.md`.

### A safety valve for active projects

Development projects can document real code, tests, resolved incidents, and architectural decisions immediately. Plans and uncertain conclusions remain visibly labeled instead of being promoted into “reusable knowledge” too early.

---

## How the workflow works

```text
Approved backlog       → Phase 3.5A → Mode A → review → verification
Mid-project change     → Phase 3.5B → approval/fast lane → Mode A or B → verification
Project completion     → finalize project document → optional safe cache rebuild
```

- **Phase 3.5A** handles already-approved `[ ]` / `[~]` work.
- **Phase 3.5B** handles new features, behavior changes, bug fixes, and improvements.
- **Mode A** processes initial triaged work and larger changes.
- **Mode B** handles a confirmed 1–2 AC change, but still requires the same impact check and six-point review.
- Cache refresh never deletes the old cache: it writes `_exp_memory.md.tmp`, validates it, then replaces the old file.

---

## Install ADD

Install both skills:

```text
acceptance-driven-development
project-experience
```

The first controls the acceptance workflow; the second gives the workflow cross-project memory when the host makes it available.

### Option 1 — CC Switch

Use the standard CC Switch skill-repository flow:

1. Select the target agent application in CC Switch.
2. Go to **Skills → Discover Skills → Repository Management → Add Skill Repository**.
3. Enter:

   ```text
   Repository URL: https://github.com/ZeusYue/acceptance-driven-development-skill
   Branch: main
   ```

4. Add the repository, return to **Discover Skills**, refresh if needed, and install:
   - `acceptance-driven-development`
   - `project-experience`
5. Start a new session in the target agent.

The repository already exposes the expected layout:

```text
skills/
├── acceptance-driven-development/SKILL.md
└── project-experience/SKILL.md
```

Do not point CC Switch at an individual `SKILL.md` file. For the complete UI walkthrough, see [CC Switch installation](./docs/CCSWITCH.md).

### “0 skills found” in CC Switch

If the repository is added but CC Switch reports zero skills, check these in order:

1. **Branch spelling:** it must be exactly `main`.
2. **Repository URL:** use the repository root, not a file URL and not a `tree/...` URL.
3. **Refresh:** return to Discover Skills and refresh the repository scan after adding it.
4. **Repository record:** if the saved branch cannot be edited, delete that repository record and add it again with `main`.
5. **Agent session:** restart the target agent or create a new session after installing.
6. **Current release:** use the repository’s latest release branch before diagnosing the skill layout.

### Option 2 — Manual installation

Copy both skill directories from `skills/` into the directory documented by your agent host:

| Agent host | Typical skills directory |
|---|---|
| Claude Code | `~/.claude/skills/` |
| Codex | `~/.codex/skills/` |
| Gemini CLI | `~/.gemini/skills/` |
| OpenCode | `~/.config/opencode/skills/` |
| Hermes | `~/.hermes/skills/` |

The final structure for Codex, for example, is:

```text
~/.codex/skills/
├── acceptance-driven-development/
│   ├── SKILL.md
│   └── references/
└── project-experience/
    └── SKILL.md
```

---

## First Run: Choose a document hub

On the first code-related request, ADD asks for a stable shared directory for project documents. A good answer is:

```text
~/project-docs/
```

It writes `~/.add-hub`, then keeps all ACs, project documents, templates, and experience cache under that hub. Obsidian is optional; a plain directory works.

---

## Migrating to v2.1

v2.1 keeps every v2.0 AC compatible. It adds:

- an explicit living-project-document lifecycle for active projects;
- schema-2 metadata for the next user-approved cache rebuild;
- portable release tests without private workstation paths;
- corrected CC Switch instructions for the actual URL + branch repository form;
- a README that explains the value before asking you to install anything.

Existing caches remain readable. Do not delete `_exp_memory.md`; ask to update the experience cache when you are ready to rebuild it safely.

---

## Support and contributions

- Report workflow gaps, documentation problems, or host-specific installation issues through [GitHub Issues](https://github.com/ZeusYue/acceptance-driven-development-skill/issues).
- For a workflow change, update the relevant skill, its reference/template, and `tests/validate-release.ps1` together.
- Keep public release tests portable: do not embed private vault paths, cache hashes, usernames, or workstation-specific assumptions.

---

## v2.1 release notes

- Reframed README around outcomes and observable workflow evidence.
- Corrected CC Switch installation to the current discovery UI and repository URL + `main` form.
- Added a focused zero-skills recovery path.
- Added living-project-document and schema-2 cache contracts to the release package.
- Kept the canonical `skills/<skill>/SKILL.md` structure for repository discovery.

Released under the [MIT License](./LICENSE). Copyright © 2026 ZeusYue.
