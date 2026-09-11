#!/usr/bin/env python3
"""Materialize one scenario in a fresh directory; never launches an agent."""

import argparse
import json
from pathlib import Path
import shutil
import subprocess


TESTS = Path(__file__).resolve().parent


def write_files(root, files):
    for relative, content in files.items():
        destination = (root / relative).resolve()
        if not destination.is_relative_to(root.resolve()) or any(part.casefold() == ".git" for part in Path(relative).parts):
            raise ValueError(f"invalid fixture path: {relative}")
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(content, encoding="utf-8")


def prepare(name, destination):
    choices = {path.stem: path for path in (TESTS / "scenarios").glob("*.json")}
    if name not in choices:
        raise ValueError(f"unknown scenario: {name}")
    scenario = json.loads(choices[name].read_text(encoding="utf-8"))
    base = TESTS / "fixtures" / scenario["base"]
    if base.parent != TESTS / "fixtures" or not base.is_dir():
        raise ValueError("unknown fixture base")
    destination = Path(destination).resolve()
    if destination.exists() and (not destination.is_dir() or any(destination.iterdir())):
        raise ValueError("scenario destination must be new or empty")
    destination.mkdir(parents=True, exist_ok=True)
    shutil.copytree(base, destination, dirs_exist_ok=True, ignore=shutil.ignore_patterns("__pycache__"))
    write_files(destination, scenario.get("initial_files", {}))
    write_files(destination, {".gitignore": "__pycache__/\n*.pyc\n"})

    def git(*arguments):
        subprocess.run(["git", "-C", str(destination), *arguments], check=True, capture_output=True, text=True)

    git("init", "--quiet")
    disabled_hooks = destination / ".git" / "disabled-hooks"
    disabled_hooks.mkdir()
    git("config", "--local", "core.hooksPath", disabled_hooks.as_posix())
    git("config", "core.autocrlf", "false")
    git("add", ".")
    git("-c", "user.name=ADD Fixture", "-c", "user.email=fixture@example.invalid", "-c", "commit.gpgsign=false", "commit", "--quiet", "-m", "Scenario baseline")
    staged = scenario.get("staged_changes", {})
    write_files(destination, staged)
    if staged:
        git("add", "--", *staged)
    write_files(destination, scenario.get("working_changes", {}))
    return scenario["user_prompt"]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("scenario")
    parser.add_argument("destination", type=Path)
    arguments = parser.parse_args()
    try:
        prompt = prepare(arguments.scenario, arguments.destination)
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"Scenario setup failed: {error}\n")
    print(f"Prepared {arguments.destination.resolve()}\n\nUser prompt:\n{prompt}")


if __name__ == "__main__":
    main()
