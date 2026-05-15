#!/usr/bin/env python3

import json
import os
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CONFIG_PATH = ROOT / "pymc_repeater" / "config.yaml"
CHANGELOG_PATH = ROOT / "pymc_repeater" / "CHANGELOG.md"
STATE_PATH = ROOT / ".github" / "upstream-dev.json"


def bump_patch(version: str) -> str:
    parts = version.split(".")
    if len(parts) != 3 or not all(part.isdigit() for part in parts):
        raise ValueError(f"Unsupported version format: {version}")
    major, minor, patch = map(int, parts)
    return f"{major}.{minor}.{patch + 1}"


def load_compare_data() -> dict:
    compare_path = os.environ["COMPARE_JSON_PATH"]
    with open(compare_path, encoding="utf-8") as file:
        return json.load(file)


def build_changelog_entry(new_version: str, old_rev: str, new_rev: str, compare_data: dict) -> str:
    compare_url = compare_data.get("html_url") or (
        f"https://github.com/pyMC-dev/pyMC_Repeater/compare/{old_rev}...{new_rev}"
    )
    commits = compare_data.get("commits", [])
    short_new = new_rev[:7]

    lines = [
        f"## {new_version}",
        "",
        f"- Sync upstream `pymcdev/pymc-repeater:dev` to `{short_new}`",
        f"- Upstream diff: {compare_url}",
    ]

    commit_subjects = []
    for commit in commits[:8]:
        message = commit.get("commit", {}).get("message", "").strip()
        subject = message.splitlines()[0] if message else ""
        if subject:
            commit_subjects.append(subject)

    if commit_subjects:
        lines.append("- Included upstream commits:")
        for subject in commit_subjects:
            lines.append(f"  - {subject}")

    lines.append("")
    lines.append("")
    return "\n".join(lines)


def main() -> None:
    new_revision = os.environ["NEW_REVISION"].strip()
    with open(STATE_PATH, encoding="utf-8") as file:
        state = json.load(file)

    old_revision = state["revision"]
    if new_revision == old_revision:
        print("No upstream revision change detected.")
        return

    config_text = CONFIG_PATH.read_text(encoding="utf-8")
    match = re.search(r'^version:\s*"?([0-9]+\.[0-9]+\.[0-9]+)"?\s*$', config_text, re.MULTILINE)
    if not match:
        raise ValueError("Could not find version in config.yaml")

    old_version = match.group(1)
    new_version = bump_patch(old_version)
    CONFIG_PATH.write_text(
        re.sub(
            r'^version:\s*"?[0-9]+\.[0-9]+\.[0-9]+"?\s*$',
            f'version: "{new_version}"',
            config_text,
            count=1,
            flags=re.MULTILINE,
        ),
        encoding="utf-8",
    )

    compare_data = load_compare_data()
    changelog = CHANGELOG_PATH.read_text(encoding="utf-8")
    header = "# Changelog\n\n"
    if not changelog.startswith(header):
        raise ValueError("Unexpected changelog format")

    new_entry = build_changelog_entry(new_version, old_revision, new_revision, compare_data)
    CHANGELOG_PATH.write_text(header + new_entry + changelog[len(header):], encoding="utf-8")

    state["revision"] = new_revision
    with open(STATE_PATH, "w", encoding="utf-8") as file:
        json.dump(state, file, indent=2)
        file.write("\n")

    print(f"Bumped add-on from {old_version} to {new_version}")
    print(f"Tracked upstream revision {old_revision[:7]} -> {new_revision[:7]}")


if __name__ == "__main__":
    main()
