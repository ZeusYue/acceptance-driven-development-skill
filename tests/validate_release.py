#!/usr/bin/env python3
"""Check the distributable package, not an agent's compliance with prose.

Python 3.10+, standard library only. Supports the simple YAML scalars and common
Markdown links/headings used by this release; this is not a general YAML or
CommonMark parser. External URLs are not fetched.
"""

from __future__ import annotations

import argparse
import html
import json
from pathlib import Path
import re
import subprocess
from urllib.parse import unquote, urlsplit


SKILL_NAME = "acceptance-driven-development"
SKILL_PATH = Path("skills") / SKILL_NAME
REQUIRED_FILES = (
    Path("README.md"), Path("README-zh.md"), Path("CHANGELOG.md"), Path("LICENSE"),
    SKILL_PATH / "SKILL.md",
    SKILL_PATH / "references/acceptance-and-evidence.md",
    SKILL_PATH / "references/design-decisions.md",
    SKILL_PATH / "references/planning-and-recovery.md",
    SKILL_PATH / "assets/ac-template.md",
    SKILL_PATH / "assets/work-record-template.md",
)
IGNORED_DIRS = {".git", ".venv", "node_modules", "__pycache__"}
PRIVATE_PATH = re.compile(
    r"\b[A-Za-z]:[/\\](?:Users|Documents and Settings)[/\\][\w.-]+"
    r"|/(?:Users|home)/[\w.-]+(?=/|\b)"
    r"|\\\\[\w.-]+\\[\w.$-]+"
)


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8-sig")


def frontmatter_errors(source: str, expected_name: str) -> list[str]:
    lines = source.splitlines()
    if not lines or lines[0] != "---":
        return ["must begin with YAML frontmatter"]
    try:
        end = lines.index("---", 1)
    except ValueError:
        return ["frontmatter has no closing delimiter"]
    values: dict[str, str] = {}
    errors = []
    for line in lines[1:end]:
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if line[0].isspace():
            continue  # Optional nested metadata is outside this check's scope.
        match = re.fullmatch(r"([\w-]+):\s*(.*)", line)
        if not match:
            errors.append("invalid top-level frontmatter entry")
            continue
        key, value = match.groups()
        if key in values:
            errors.append(f"duplicate frontmatter key: {key}")
        values[key] = value.strip()
    for key in ("name", "description"):
        value = values.get(key, "")
        if value.startswith('"'):
            try:
                value = json.loads(value)
            except (json.JSONDecodeError, ValueError):
                errors.append(f"invalid quoted {key}")
                continue
        elif value.startswith("'"):
            if len(value) < 2 or not value.endswith("'"):
                errors.append(f"invalid quoted {key}")
                continue
            value = value[1:-1].replace("''", "'")
        elif ": " in value or " #" in value:
            errors.append(f"quote {key} when it contains YAML punctuation")
        elif value.lower() in ("true", "false", "null", "~") or value.startswith(("[", "{")) or re.fullmatch(r"[-+]?\d+(?:\.\d+)?", value):
            errors.append(f"{key} must be a string, not another YAML value")
        if not isinstance(value, str) or not value.strip() or value in ("|", ">", "|-", ">-"):
            errors.append(f"{key} must be a nonempty single-line string")
        elif key == "name" and value != expected_name:
            errors.append(f"name must match skill directory: {expected_name}")
        elif key == "description" and (len(value) > 1024 or "<" in value or ">" in value):
            errors.append("description must be at most 1024 characters and contain no angle brackets")
    return errors


def prose_lines(source: str) -> list[str]:
    """Blank fenced code/comments while retaining line numbers for diagnostics."""
    source = re.sub(r"<!--.*?-->", lambda m: "\n" * m[0].count("\n"), source, flags=re.S)
    result = []
    fence = ""
    for line in source.splitlines():
        match = re.match(r"^\s{0,3}(`{3,}|~{3,})(.*)$", line)
        if match and not fence:
            fence = match[1]
            result.append("")
        elif fence:
            if match and match[1][0] == fence[0] and len(match[1]) >= len(fence) and not match[2].strip():
                fence = ""
            result.append("")
        else:
            result.append(line)
    return result


def heading_anchors(source: str) -> set[str]:
    anchors: set[str] = set()
    lines = prose_lines(source)
    for index, line in enumerate(lines):
        anchors.update(re.findall(r'\b(?:id|name)=["\']([^"\']+)["\']', line))
        match = re.match(r"^\s{0,3}#{1,6}\s+(.+?)(?:\s+#+)?\s*$", line)
        title = match[1] if match else ""
        if not title and index and re.fullmatch(r"\s{0,3}(?:=+|-+)\s*", line):
            title = lines[index - 1].strip()
        if not title:
            continue
        title = re.sub(r"<[^>]+>", "", html.unescape(title))
        title = re.sub(r"\[([^]]+)\]\([^)]*\)", r"\1", title)
        slug = re.sub(r"[^\w\- ]", "", title.lower()).replace(" ", "-")
        candidate, suffix = slug, 0
        while candidate in anchors:
            suffix += 1
            candidate = f"{slug}-{suffix}"
        anchors.add(candidate)
    return anchors


def markdown_links(source: str) -> list[tuple[int, str]]:
    """Inline links/images, reference links, and HTML href/src attributes."""
    lines = [re.sub(r"(`+).*?\1", "CODE", line) for line in prose_lines(source)]
    definitions = {}
    links = []
    for line_number, line in enumerate(lines, 1):
        definition = re.match(r"^\s{0,3}\[([^]]+)\]:\s*(?:<([^>]+)>|(\S+))", line)
        if definition:
            target = definition[2] or definition[3]
            definitions[definition[1].casefold()] = target
            links.append((line_number, target))
    for line_number, line in enumerate(lines, 1):
        if re.match(r"^\s{0,3}\[[^]]+\]:", line):
            continue
        for match in re.finditer(r"\[[^]\n]+\]\(\s*(?:<([^>]+)>|([^\s)]+))(?:\s+[\"'][^\n]*?[\"'])?\s*\)", line):
            links.append((line_number, match[1] or match[2]))
        for match in re.finditer(r"\[([^]\n]+)\]\[([^]\n]*)\]", line):
            key = (match[2] or match[1]).casefold()
            links.append((line_number, definitions.get(key, f"MISSING_REFERENCE:{key}")))
        for match in re.finditer(r'\b(?:href|src)=["\']([^"\']+)["\']', line):
            links.append((line_number, html.unescape(match[1])))
    return links


def link_errors(path: Path, source: str, boundary: Path) -> list[str]:
    errors = []
    for line_number, link in markdown_links(source):
        prefix = f"line {line_number}: "
        if link.startswith("MISSING_REFERENCE:"):
            errors.append(prefix + "undefined Markdown reference: " + link.split(":", 1)[1])
            continue
        if re.match(r"^[A-Za-z]:[/\\]", link) or link.startswith("\\"):
            errors.append(prefix + f"absolute filesystem link is not portable: {link}")
            continue
        try:
            parsed = urlsplit(link)
        except ValueError:
            errors.append(prefix + f"invalid link: {link}")
            continue
        if parsed.scheme == "file":
            errors.append(prefix + f"absolute filesystem link is not portable: {link}")
            continue
        if parsed.scheme or parsed.netloc:
            continue
        target_path = unquote(parsed.path)
        if target_path.startswith("/") or "\\" in target_path:
            errors.append(prefix + f"use a portable relative link: {link}")
            continue
        target = (path.parent / target_path).resolve() if target_path else path.resolve()
        if not target.is_relative_to(boundary.resolve()):
            errors.append(prefix + f"link escapes package boundary: {link}")
        elif not target.exists():
            errors.append(prefix + f"broken relative link: {link}")
        elif parsed.fragment and target.is_file() and target.suffix.lower() == ".md":
            try:
                anchors = heading_anchors(read_text(target))
            except (OSError, UnicodeError):
                errors.append(prefix + f"cannot read linked Markdown: {link}")
                continue
            if unquote(parsed.fragment) not in anchors:
                errors.append(prefix + f"missing heading anchor: {link}")
    return errors


def validate(root: Path, require_clean_worktree: bool = False) -> list[str]:
    root = root.resolve()
    errors = [f"missing required file: {path.as_posix()}" for path in REQUIRED_FILES if not (root / path).is_file()]
    skills = root / "skills"
    if skills.is_dir():
        for directory in sorted(path for path in skills.iterdir() if path.is_dir()):
            if directory.name != SKILL_NAME:
                errors.append(f"unexpected skill directory: {directory.name}")
    package = root / SKILL_PATH
    for path in sorted(root.rglob("*.md")):
        if any(part in IGNORED_DIRS for part in path.relative_to(root).parts):
            continue
        label = path.relative_to(root).as_posix()
        try:
            source = read_text(path)
        except (OSError, UnicodeError) as error:
            errors.append(f"{label}: cannot read UTF-8 text: {error}")
            continue
        installable = path.is_relative_to(package)
        boundary = package if installable else root
        if not path.resolve().is_relative_to(boundary.resolve()):
            errors.append(f"{label}: file resolves outside its package")
            continue
        if installable:
            if PRIVATE_PATH.search(source):
                errors.append(f"{label}: contains a private machine-specific filesystem path")
            if path == package / "SKILL.md":
                errors.extend(f"{label}: {error}" for error in frontmatter_errors(source, package.name))
        errors.extend(f"{label}: {error}" for error in link_errors(path, source, boundary))
    if require_clean_worktree:
        try:
            result = subprocess.run(["git", "-C", str(root), "status", "--porcelain"], capture_output=True, text=True, check=True)
            if result.stdout.strip():
                errors.append("Git worktree is not clean")
        except (OSError, subprocess.CalledProcessError):
            errors.append("cannot inspect Git worktree")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--require-clean-worktree", action="store_true")
    arguments = parser.parse_args()
    errors = validate(arguments.root, arguments.require_clean_worktree)
    if errors:
        print(f"FAIL: {len(errors)} release structure issue(s)")
        for error in errors:
            print(f" - {error}")
        return 1
    print("PASS: release files, skill metadata, and local links are valid.")
    print("Agent behavior requires separate scenario evaluation; it is not certified by this check.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
