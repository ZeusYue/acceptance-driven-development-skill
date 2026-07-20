# Acceptance-Driven Development (ADD) v2.2

<p align="center">
  <strong>The AI skill pack that makes “done” a checklist, not a feeling.</strong><br>
  Turn coding-agent output into acceptance criteria, review evidence, and a project memory that survives the session.
</p>

<p align="center">
  <a href="./README-zh.md">简体中文</a> ·
  <a href="#try-add-in-60-seconds">Try it</a> ·
  <a href="#install-add">Install</a> ·
  <a href="#0-skills-found-in-cc-switch">CC Switch help</a>
</p>

---

## Your agent said “done.” You disagree.

You ask an agent to build a feature. It writes code, maybe the build passes, and it confidently says **“Done.”**

Then you open the app:

- a button does nothing;
- one edge case is missing;
- the requested behavior was misunderstood;
- the fix broke another screen;
- the agent has already moved on.

**Coding agents are optimistic. They can produce code faster than they can prove that the result satisfies your intent.**

ADD exists to close that gap. It gives the agent a visible contract for what must be built, what must be checked, and what still needs your hands-on confirmation.

---

## How ADD closes the loop

```text
YOUR IDEA
    │
    ▼
Agent clarifies intent ───────────────► no silent guessing
    │
    ▼
Acceptance criteria (AC.md) ──────────► you review the contract
    │
    ▼
Impact analysis before code ───────────► working behavior is protected
    │
    ▼
Implement + six-point review ─────────► code is not the exit condition
    │
    ▼
Fresh verification / your test ────────► [ ] → [!] → [x]
    │
    ▼
Living project document ──────────────► the next project starts smarter
```

The practical rule is simple:

> The agent cannot honestly call a feature complete while its acceptance criteria still say it is unfinished, unverified, blocked, or only partially done.

---

## Before ADD / After ADD

| Without ADD | With ADD |
|---|---|
| “It compiles, so it is done.” | “AC-12 passed its verification command; here is the result.” |
| The agent assumes your intent. | You approve behavior changes before implementation. |
| A small fix breaks another feature unnoticed. | Impact analysis marks affected criteria for re-verification. |
| GUI work is declared complete without being clicked. | It stays visible as `[!] [manual]` until someone verifies it. |
| A repeated failure receives another patch. | Three failures trigger diagnosis, redesign, guidance, or deferral. |
| Each project starts from zero. | Project documents and evidence-backed experience inform the next task. |

---

## Try ADD in 60 seconds

Load the skill once for the session, then send a request like:

```text
Build a photo browser with ADD.
```

For a new project, ADD asks questions, records a design, drafts an acceptance table, and waits for approval before building.

For an existing project, try:

```text
Continue ImageView with ADD.
```

For a change to a working project, try:

```text
Add a bulk-delete action. Use ADD.
```

You should see phase announcements, the affected acceptance criteria, a review result, and either fresh command output or a specific user-test checklist. That is the point: the workflow should be inspectable, not mysterious.

---

## What you get as the project grows

### An honest acceptance table

`AC.md` is the acceptance source of truth.

| Mark | Meaning |
|---|---|
| `[ ]` | Not implemented |
| `[~]` | Partially implemented |
| `[x]` | Freshly verified passing |
| `[!] [manual]` | Implemented; needs a hands-on check |
| `[!] [affected]` | Previously passed but affected by another change |
| `[!] [blocked]` | Verification unavailable; unblock condition recorded |
| `[>]` | Explicitly deferred |
| `[-]` | Explicitly deprecated |

### A project record that stays useful during development

```text
$DOC_HUB/<ProjectName>/
├── AC.md                  # acceptance state
├── design.md              # approved design, when needed
└── <ProjectName>.md       # living architecture, risks, patterns, and evidence
```

ADD owns the project-document lifecycle. `project-experience` reads these documents and turns proven cross-project lessons into a compact experience cache.

### A workflow that becomes more precise when needed

You do not need to learn internal terms before trying ADD. Later, when you want to inspect the workflow:

- **Phase 3.5A** means “implement approved backlog safely.”
- **Phase 3.5B** means “change behavior, fix a bug, or add a feature safely.”
- **Mode A** is batch implementation; **Mode B** is a lightweight confirmed change.
- Both still require impact analysis, review, and verification.

---

## Install ADD

Install both skills:

```text
acceptance-driven-development
project-experience
```

The first enforces the acceptance workflow. The second provides reusable project experience when the host supports it.

### Option 1 — CC Switch

1. Select the target agent application.
2. Open **Skills → Discover Skills → Repository Management → Add Skill Repository**.
3. Enter:

   ```text
   Repository URL: https://github.com/ZeusYue/acceptance-driven-development-skill
   Branch: main
   ```

4. Return to **Discover Skills**, refresh if needed, and install:
   - `acceptance-driven-development`
   - `project-experience`
5. Start a new agent session.

The repository already uses the discovery layout CC Switch scans recursively:

```text
skills/
├── acceptance-driven-development/SKILL.md
└── project-experience/SKILL.md
```

For detailed troubleshooting, see [CC Switch installation](./docs/CCSWITCH.md).

### 0 skills found in CC Switch

After URL and branch are correct, zero skills can still be a temporary **GitHub archive download or refresh** failure rather than a repository-layout problem.

Check in this order:

1. Repository URL is the repository root — not a file URL or `tree/...` URL.
2. Branch is exactly `main`.
3. Return to Discover Skills and refresh the scan.
4. Restart CC Switch, then refresh again.
5. If the saved record cannot be corrected, delete it and add it again.

#### Network and proxy

CC Switch discovers a repository by downloading its GitHub branch archive. If GitHub access is restricted or unstable, the UI may show zero skills without explaining the download failure.

- Open this address in a browser to verify the archive path is reachable:

  ```text
  https://github.com/ZeusYue/acceptance-driven-development-skill/archive/refs/heads/main.zip
  ```

- If it does not download, switch networks or configure the system / CC Switch network proxy according to your environment.
- After network or proxy changes, restart CC Switch and refresh Discover Skills.
- If the archive downloads but discovery still shows zero, use manual installation and report the result in an issue with your CC Switch version and screenshots.

### Option 2 — Manual installation

Copy both folders from `skills/` into the skill directory documented by your host:

| Agent host | Typical skills directory |
|---|---|
| Claude Code | `~/.claude/skills/` |
| Codex | `~/.codex/skills/` |
| Gemini CLI | `~/.gemini/skills/` |
| OpenCode | `~/.config/opencode/skills/` |
| Hermes | `~/.hermes/skills/` |

---

## First Run: choose a document hub

On the first code-related request, ADD asks for one stable directory shared across projects. A good answer is:

```text
~/project-docs/
```

ADD writes `~/.add-hub` and keeps project ACs, documents, templates, and the optional experience cache there. Obsidian is helpful but not required.

---

## Migrating to v2.2

Existing AC tables remain compatible. v2.2 adds:

- a problem-first README and a quick experiential path;
- clear CC Switch network/proxy diagnosis after URL and branch checks;
- living-project-document and schema-2 cache contracts from v2.1;
- portable release validation that contains no private workstation paths.

Do not delete `_exp_memory.md` to refresh it. Ask to update the experience cache so it can be rebuilt safely.

---

## Support and contributions

- Report workflow gaps, documentation problems, or installation results through [GitHub Issues](https://github.com/ZeusYue/acceptance-driven-development-skill/issues).
- When changing a workflow contract, update its skill, template/reference, README, and `tests/validate-release.ps1` together.

Released under the [MIT License](./LICENSE). Copyright © 2026 ZeusYue.
