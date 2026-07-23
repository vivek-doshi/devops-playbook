#!/usr/bin/env python3
"""
catalog/scripts/validate-catalog.py
Validate service catalog entries for schema, references, and governance rules.

Usage:
  python catalog/scripts/validate-catalog.py
  python catalog/scripts/validate-catalog.py --service api-gateway
  python catalog/scripts/validate-catalog.py --strict
  python catalog/scripts/validate-catalog.py --skip-url-check

Exit codes:
  0: no failures
  1: failures present
"""

import argparse
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
CATALOG_SERVICES = ROOT / "catalog" / "services"
CATALOG_TEAMS = ROOT / "catalog" / "teams"
BUDGETS_FILE = ROOT / "finops" / "config" / "budgets.yaml"
BASE_DEPLOYMENT_FILE = ROOT / "cd" / "kubernetes" / "_base" / "deployment.yaml"


def load_yaml(path: Path) -> dict[str, Any]:
    import yaml  # noqa: PLC0415

    with path.open("r", encoding="utf-8") as f:
        data = yaml.safe_load(f)
    return data if isinstance(data, dict) else {}


def collect_teams() -> set[str]:
    teams: set[str] = set()
    for file in sorted(CATALOG_TEAMS.glob("*.yaml")):
        entry = load_yaml(file)
        name = entry.get("metadata", {}).get("name")
        if isinstance(name, str) and name.strip():
            teams.add(name.strip())
    return teams


def collect_cost_centers() -> set[str]:
    data = load_yaml(BUDGETS_FILE)
    centers: set[str] = set()
    for b in data.get("budgets", []):
        center = b.get("cost_center")
        if isinstance(center, str) and center.strip():
            centers.add(center.strip())
    return centers


def ensure_base_deployment_has_app_label() -> tuple[bool, str]:
    text = BASE_DEPLOYMENT_FILE.read_text(encoding="utf-8")
    if "labels:" in text and "app:" in text:
        return True, ""
    return (
        False,
        "ERROR: cd/kubernetes/_base/deployment.yaml does not define required app label pattern",
    )


def _require_string(obj: dict[str, Any], key_path: list[str], errors: list[str]) -> str:
    cur: Any = obj
    for k in key_path:
        cur = cur.get(k) if isinstance(cur, dict) else None
    path_text = ".".join(key_path)
    if not isinstance(cur, str) or not cur.strip():
        errors.append(f"ERROR: {path_text} is required and must be a non-empty string")
        return ""
    return cur.strip()


def validate_service(
    service_file: Path,
    team_names: set[str],
    cost_centers: set[str],
    skip_url_check: bool,
) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []

    data = load_yaml(service_file)

    api_version = _require_string(data, ["apiVersion"], errors)
    kind = _require_string(data, ["kind"], errors)
    if api_version and api_version != "catalog/v1":
        errors.append(f"ERROR: apiVersion must be catalog/v1, got '{api_version}'")
    if kind and kind != "Service":
        errors.append(f"ERROR: kind must be Service, got '{kind}'")

    metadata_name = _require_string(data, ["metadata", "name"], errors)
    owner = _require_string(data, ["metadata", "owner"], errors)
    lifecycle = _require_string(data, ["metadata", "lifecycle"], errors)

    valid_lifecycle = {"alpha", "beta", "stable", "deprecated"}
    if lifecycle and lifecycle not in valid_lifecycle:
        errors.append("ERROR: metadata.lifecycle must be one of alpha|beta|stable|deprecated")

    if owner and owner not in team_names:
        errors.append(f"ERROR: owner '{owner}' not found in catalog/teams/")

    spec = data.get("spec", {}) if isinstance(data.get("spec"), dict) else {}
    _require_string(data, ["metadata", "display_name"], errors)
    _require_string(data, ["metadata", "description"], errors)
    _require_string(data, ["spec", "contact"], errors)
    _require_string(data, ["spec", "image"], errors)
    _require_string(data, ["spec", "cost_center"], errors)
    _require_string(data, ["spec", "environment"], errors)
    _require_string(data, ["spec", "data_classification"], errors)

    oncall = spec.get("oncall", {}) if isinstance(spec.get("oncall"), dict) else {}
    if (
        not isinstance(oncall.get("pagerduty_service"), str)
        or not oncall.get("pagerduty_service", "").strip()
    ):
        errors.append("ERROR: spec.oncall.pagerduty_service is required")
    if (
        not isinstance(oncall.get("slack_channel"), str)
        or not oncall.get("slack_channel", "").strip()
    ):
        errors.append("ERROR: spec.oncall.slack_channel is required")

    namespaces = spec.get("namespaces", [])
    if not isinstance(namespaces, list) or not namespaces:
        errors.append("ERROR: spec.namespaces must be a non-empty list")
    else:
        for item in namespaces:
            if not isinstance(item, str) or "/" not in item:
                errors.append(
                    f"ERROR: namespace entry '{item}' must match <namespace>/<deployment-name>"
                )
                continue
            _, deployment_name = item.split("/", 1)
            if metadata_name and deployment_name != metadata_name:
                warnings.append(
                    f"WARNING: namespace entry '{item}' deployment segment differs from metadata.name '{metadata_name}'"
                )

    cost_center = spec.get("cost_center")
    if isinstance(cost_center, str) and cost_center not in cost_centers:
        errors.append(f"ERROR: cost_center '{cost_center}' not found in finops/config/budgets.yaml")

    compliance_frameworks = spec.get("compliance_frameworks", [])
    if not isinstance(compliance_frameworks, list):
        errors.append("ERROR: spec.compliance_frameworks must be a list")
        compliance_frameworks = []

    classification = spec.get("data_classification")
    if (
        lifecycle == "stable"
        and classification == "confidential"
        and "SOC2" not in compliance_frameworks
    ):
        errors.append(
            "ERROR: stable confidential services must include SOC2 in spec.compliance_frameworks"
        )

    slo = spec.get("slo", {}) if isinstance(spec.get("slo"), dict) else {}
    slo_file = slo.get("definition_file")
    if lifecycle in {"beta", "stable"}:
        if not isinstance(slo_file, str) or not slo_file.strip():
            errors.append("ERROR: spec.slo.definition_file is required for lifecycle beta/stable")
        else:
            target = ROOT / slo_file
            if not target.exists():
                errors.append(f"ERROR: slo.definition_file not found: {slo_file}")

    runbook_url = spec.get("runbook_url")
    if lifecycle == "stable":
        if not isinstance(runbook_url, str) or not runbook_url.strip():
            errors.append("ERROR: runbook_url must be set for lifecycle stable")

    if isinstance(runbook_url, str) and runbook_url.strip() and not skip_url_check:
        try:
            import requests  # noqa: PLC0415

            resp = requests.get(runbook_url, timeout=10)
            if resp.status_code != 200:
                warnings.append(f"WARNING: runbook_url returns {resp.status_code}")
        except Exception as exc:  # noqa: BLE001
            warnings.append(f"WARNING: runbook_url check failed: {exc}")

    return errors, warnings


def service_files(service_name: str | None) -> list[Path]:
    if service_name:
        target = CATALOG_SERVICES / f"{service_name}.yaml"
        return [target]
    return sorted(CATALOG_SERVICES.glob("*.yaml"))


def main() -> None:
    parser = argparse.ArgumentParser(description="Validate service catalog entries")
    parser.add_argument("--strict", action="store_true", help="Treat warnings as errors")
    parser.add_argument("--skip-url-check", action="store_true", help="Skip HTTP URL validation")
    parser.add_argument("--service", help="Validate only one service name (without .yaml)")
    args = parser.parse_args()

    if not CATALOG_SERVICES.exists():
        print("ERROR: catalog/services directory not found")
        sys.exit(1)

    teams = collect_teams()
    if not teams:
        print("ERROR: no team entries found in catalog/teams/")
        sys.exit(1)

    cost_centers = collect_cost_centers()
    has_app_label, base_err = ensure_base_deployment_has_app_label()
    if not has_app_label:
        print(base_err)
        sys.exit(1)

    files = service_files(args.service)
    if args.service and not files[0].exists():
        print(f"ERROR: service file not found: catalog/services/{args.service}.yaml")
        sys.exit(1)

    passed = 0
    failed = 0
    warning_count = 0

    for file in files:
        rel = file.relative_to(ROOT).as_posix()
        print(f"Validating {rel}...", end=" ")
        errs, warns = validate_service(file, teams, cost_centers, args.skip_url_check)
        if errs or (args.strict and warns):
            print("FAIL")
            for e in errs:
                print(f"  {e}")
            for w in warns:
                print(f"  {w}")
            failed += 1
            warning_count += len(warns)
        else:
            print("PASS")
            for w in warns:
                print(f"  {w}")
            passed += 1
            warning_count += len(warns)

    print(
        f"\nSummary: {passed} passed, {failed} failed, {warning_count} warning"
        f"{'s' if warning_count != 1 else ''}"
    )

    if failed > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
