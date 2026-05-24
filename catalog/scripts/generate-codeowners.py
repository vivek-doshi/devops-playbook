#!/usr/bin/env python3
"""
catalog/scripts/generate-codeowners.py
Generate CODEOWNERS entries from catalog team ownership metadata.

Usage:
  python catalog/scripts/generate-codeowners.py > .github/CODEOWNERS
  python catalog/scripts/generate-codeowners.py --output .github/CODEOWNERS
"""

import argparse
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
TEAM_DIR = ROOT / "catalog" / "teams"


def load_yaml(path: Path) -> dict[str, Any]:
    import yaml  # noqa: PLC0415

    with path.open("r", encoding="utf-8") as f:
        data = yaml.safe_load(f)
    return data if isinstance(data, dict) else {}


def normalize_owner(value: str) -> str:
    v = value.strip()
    if not v:
        return v
    if v.startswith("@"):
        return v
    if "@" in v and "/" not in v:
        local = v.split("@", 1)[0]
        return f"@{local}"
    return f"@{v}"


def generate_lines(repo_slug: str) -> list[str]:
    lines = [
        "# Code owners generated from catalog/teams/",
        "# Auto-generated from catalog/teams/ - run python catalog/scripts/generate-codeowners.py to regenerate.",
        "# Do not edit manually.",
        "",
    ]

    for file in sorted(TEAM_DIR.glob("*.yaml")):
        team = load_yaml(file)
        name = team.get("metadata", {}).get("name")
        spec = team.get("spec", {}) if isinstance(team.get("spec"), dict) else {}
        members = spec.get("members", [])
        owns = spec.get("owns", [])

        if not isinstance(name, str) or not name.strip() or not isinstance(members, list):
            continue

        owners = [normalize_owner(m) for m in members if isinstance(m, str) and m.strip()]
        if not owners:
            owners = [f"@{repo_slug}/{name.strip()}"]

        for path in owns if isinstance(owns, list) else []:
            if isinstance(path, str) and path.strip():
                lines.append(f"{path} {' '.join(owners)}")

    return lines


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate CODEOWNERS from catalog teams")
    parser.add_argument("--output", help="Write to file instead of stdout")
    parser.add_argument(
        "--repo-slug",
        default="your-org",
        help="GitHub org/user slug used for fallback @org/team owners",
    )
    args = parser.parse_args()

    lines = generate_lines(args.repo_slug)
    content = "\n".join(lines).rstrip() + "\n"

    if args.output:
        out_path = ROOT / args.output
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(content, encoding="utf-8")
    else:
        print(content, end="")


if __name__ == "__main__":
    main()
