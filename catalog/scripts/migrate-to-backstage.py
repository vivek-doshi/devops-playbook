#!/usr/bin/env python3
"""
catalog/scripts/migrate-to-backstage.py
Generate Backstage catalog component YAMLs from service catalog entries.

Usage:
  python catalog/scripts/migrate-to-backstage.py
  python catalog/scripts/migrate-to-backstage.py --output-dir backstage/catalog
"""

import argparse
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
SERVICE_DIR = ROOT / "catalog" / "services"


def load_yaml(path: Path) -> dict[str, Any]:
    import yaml  # noqa: PLC0415

    with path.open("r", encoding="utf-8") as f:
        data = yaml.safe_load(f)
    return data if isinstance(data, dict) else {}


def emit_yaml(path: Path, data: dict[str, Any]) -> None:
    import yaml  # noqa: PLC0415

    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        yaml.safe_dump(data, f, sort_keys=False)


def to_backstage(service: dict[str, Any], repo_slug: str) -> dict[str, Any]:
    meta = service.get("metadata", {}) if isinstance(service.get("metadata"), dict) else {}
    spec = service.get("spec", {}) if isinstance(service.get("spec"), dict) else {}
    oncall = spec.get("oncall", {}) if isinstance(spec.get("oncall"), dict) else {}

    name = meta.get("name", "unknown-service")
    owner = meta.get("owner", "unknown-team")
    namespace_entries = spec.get("namespaces", []) if isinstance(spec.get("namespaces"), list) else []

    return {
        "apiVersion": "backstage.io/v1alpha1",
        "kind": "Component",
        "metadata": {
            "name": name,
            "description": meta.get("description", ""),
            "annotations": {
                "github.com/project-slug": f"{repo_slug}/{name}",  # <-- CHANGE THIS if repo naming differs from service names.
                "pagerduty.com/service-id": oncall.get("pagerduty_service", ""),
                "backstage.io/kubernetes-label-selector": f"app={name}",
            },
            "links": [
                {"url": spec.get("runbook_url", ""), "title": "Runbook"},
                {"url": spec.get("docs_url", ""), "title": "Documentation"},
            ],
            "tags": [
                str(spec.get("environment", "")),
                str(spec.get("data_classification", "")),
                str(spec.get("cost_center", "")),
            ],
        },
        "spec": {
            "type": "service",
            "lifecycle": meta.get("lifecycle", "alpha"),
            "owner": f"group:{owner}",
            "system": "platform",  # <-- CHANGE THIS to your domain system model.
            "dependsOn": [
                f"resource:{d.get('name')}"
                for d in spec.get("dependencies", [])
                if isinstance(d, dict) and d.get("name")
            ],
            "providesApis": [f"{name}-api"],
        },
        "x-catalog-metadata": {
            "sourceNamespaces": namespace_entries,
            "sloDefinitionFile": spec.get("slo", {}).get("definition_file", ""),
            "slackChannel": oncall.get("slack_channel", ""),
        },
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Migrate service catalog entries to Backstage YAML")
    parser.add_argument("--output-dir", default="backstage/catalog", help="Output directory for Backstage files")
    parser.add_argument("--repo-slug", default="your-org/your-repo", help="GitHub repo slug for annotations")
    args = parser.parse_args()

    out_root = ROOT / args.output_dir
    files = sorted(SERVICE_DIR.glob("*.yaml"))
    if not files:
        print("No service catalog entries found in catalog/services/")
        return

    for file in files:
        service = load_yaml(file)
        name = service.get("metadata", {}).get("name", file.stem)
        backstage_entry = to_backstage(service, args.repo_slug)
        out_file = out_root / f"{name}.yaml"
        emit_yaml(out_file, backstage_entry)
        print(f"Generated {out_file.relative_to(ROOT).as_posix()}")


if __name__ == "__main__":
    main()
