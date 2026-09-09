#!/usr/bin/env python3
"""Static checks for the SwiftUI Expert skill.

The validator intentionally checks documentation contracts rather than trying to
compile placeholder Swift snippets. It is dependency-free so maintainers can run
it in any checkout.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


REFERENCE_LINE_LIMIT = 300
TOC_MARKERS = ("## Table of Contents", "## Contents", "## Índice")
LOCAL_PATH_RE = re.compile(
    r"(?<![A-Za-z0-9_])((?:references|examples|scripts|tests)/[A-Za-z0-9_./-]+)"
)
FENCE_RE = re.compile(r"```(?:swift|swiftui)?\s*\n(.*?)```", re.DOTALL | re.IGNORECASE)
ACTOR_AVAILABILITY_RE = re.compile(r"Actors?\s+Swift\s*\|\s*iOS\s*17", re.IGNORECASE)
SENDABLE_CLASS_RE = re.compile(
    r"(?:final\s+)?class\s+\w+[^\n{]*\bSendable\b[^\n{]*\{(.*?)\}",
    re.DOTALL,
)
MUTABLE_PROPERTY_RE = re.compile(r"\bvar\s+[A-Za-z_][A-Za-z0-9_]*\s*(?:=|:)")


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _frontmatter_errors(skill_dir: Path) -> list[str]:
    path = skill_dir / "SKILL.md"
    if not path.is_file():
        return ["SKILL.md is missing"]

    text = _read(path)
    if not text.startswith("---\n"):
        return ["SKILL.md must start with YAML frontmatter"]

    closing = text.find("\n---", 4)
    if closing == -1:
        return ["SKILL.md frontmatter is not closed"]

    frontmatter = text[4:closing]
    errors = []
    for key in ("name", "description"):
        if not re.search(rf"^{key}:\s*\S", frontmatter, re.MULTILINE):
            errors.append(f"SKILL.md frontmatter is missing {key}")
    return errors


def _referenced_paths(markdown: str) -> set[str]:
    return {match.group(1).rstrip(".,:;)") for match in LOCAL_PATH_RE.finditer(markdown)}


def _code_blocks(text: str) -> list[str]:
    return [match.group(1) for match in FENCE_RE.finditer(text)]


def _reference_errors(skill_dir: Path) -> list[str]:
    errors: list[str] = []
    markdown_files = sorted(skill_dir.rglob("*.md"))

    for markdown_file in markdown_files:
        text = _read(markdown_file)
        relative = markdown_file.relative_to(skill_dir)

        for reference in _referenced_paths(text):
            if reference.startswith("https://") or reference.startswith("http://"):
                continue
            if not (skill_dir / reference).is_file():
                errors.append(f"{relative}: referenced path does not exist: {reference}")

        if relative.parts[:1] == ("references",) and len(text.splitlines()) > REFERENCE_LINE_LIMIT:
            if not any(marker in text for marker in TOC_MARKERS):
                errors.append(f"{relative}: references longer than 300 lines need a table of contents")

        has_combine_import = "import Combine" in text
        for block in _code_blocks(text):
            if "ObservableObject" in block or "@Published" in block:
                if not has_combine_import:
                    errors.append(f"{relative}: ObservableObject/@Published snippets must import Combine")

            for match in SENDABLE_CLASS_RE.finditer(block):
                if MUTABLE_PROPERTY_RE.search(match.group(1)):
                    errors.append(
                        f"{relative}: mutable reference types must use actor isolation or an explicit safe synchronization strategy before Sendable"
                    )

        if ACTOR_AVAILABILITY_RE.search(text):
            errors.append(f"{relative}: actor availability claim is stale; actors are not iOS 17-only")

    return errors


def validate_skill(skill_dir: Path | str) -> list[str]:
    """Return actionable validation errors for a skill directory."""

    root = Path(skill_dir).expanduser().resolve()
    if not root.is_dir():
        return [f"skill directory does not exist: {root}"]
    return _frontmatter_errors(root) + _reference_errors(root)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("skill_dir", type=Path, help="path to the skill directory")
    args = parser.parse_args(argv)

    errors = validate_skill(args.skill_dir)
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        print(f"{len(errors)} validation error(s)", file=sys.stderr)
        return 1

    print(f"OK: {Path(args.skill_dir).resolve()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
