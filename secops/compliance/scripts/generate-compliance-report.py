#!/usr/bin/env python3
# ============================================================
# TEMPLATE: Compliance Script - Generate Compliance Report
# WHEN TO USE: Convert control libraries + evidence into compliance score output
# PREREQUISITES: PyYAML and evidence artifacts from collect-evidence.sh
# SECRETS NEEDED: None
# WHAT TO CHANGE: fail-below threshold and output format by workflow
# RELATED FILES: secops/compliance/control-library/*.yaml
# MATURITY: Beta
# ============================================================

"""
secops/compliance/scripts/generate-compliance-report.py

Generate compliance reports from machine-readable control libraries and collected
cluster evidence artifacts.

Score formula:
  implemented / (total - not_applicable)
  partial contributes 0.5

Usage:
  python secops/compliance/scripts/generate-compliance-report.py \
    --evidence-dir ./evidence-20260523

  python secops/compliance/scripts/generate-compliance-report.py \
    --evidence-dir ./evidence-20260523 --format markdown

  python secops/compliance/scripts/generate-compliance-report.py \
    --evidence-dir ./evidence-20260523 --fail-below 0.85
"""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

try:
    import yaml
except ImportError as exc:  # pragma: no cover
    raise SystemExit("PyYAML is required: pip install pyyaml") from exc


FRAMEWORK_FILES = {
    "SOC2": "soc2-controls.yaml",
    "CIS-Kubernetes": "cis-kubernetes.yaml",
    "ISO27001": "iso27001.yaml",
}


def load_yaml(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        return yaml.safe_load(handle) or {}


def load_json(path: Path, default: Any) -> Any:
    if not path.exists():
        return default
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def normalize_framework_key(raw: str) -> str:
    upper = raw.upper()
    if upper.startswith("SOC2"):
        return "SOC2"
    if upper.startswith("CIS"):
        return "CIS-Kubernetes"
    if upper.startswith("ISO"):
        return "ISO27001"
    return raw


def control_weight(status: str) -> float:
    status_map = {
        "implemented": 1.0,
        "partial": 0.5,
        "planned": 0.0,
        "not_applicable": 0.0,
    }
    return status_map.get(status, 0.0)


def score_controls(controls: list[dict[str, Any]]) -> tuple[float, dict[str, int]]:
    counts = {
        "total_controls": len(controls),
        "implemented": 0,
        "partial": 0,
        "planned": 0,
        "not_applicable": 0,
    }
    weighted_sum = 0.0

    for control in controls:
        status = control.get("status", "planned")
        if status not in counts:
            status = "planned"
        counts[status] += 1
        weighted_sum += control_weight(status)

    denominator = counts["total_controls"] - counts["not_applicable"]
    score = 0.0 if denominator <= 0 else (weighted_sum / denominator)
    return score, counts


def collect_failing_checks(evidence_dir: Path) -> list[dict[str, Any]]:
    failures: list[dict[str, Any]] = []

    kube_bench = load_json(evidence_dir / "kube-bench" / "results.json", {})
    for control in kube_bench.get("Controls", []):
        for test in control.get("tests", []):
            for result in test.get("results", []):
                if str(result.get("status", "")).upper() == "FAIL":
                    failures.append(
                        {
                            "tool": "kube-bench",
                            "id": result.get("test_number"),
                            "description": result.get("test_desc"),
                            "status": "FAIL",
                        }
                    )

    kyverno_violations = load_json(evidence_dir / "kyverno" / "violations.json", {})
    for report in kyverno_violations.get("failingReports", []):
        for result in report.get("results", []):
            failures.append(
                {
                    "tool": "kyverno",
                    "id": result.get("policy"),
                    "description": result.get("message"),
                    "namespace": report.get("namespace"),
                    "status": result.get("result"),
                }
            )

    return failures


def extract_cluster_name(evidence_dir: Path) -> str:
    cluster_info = load_json(evidence_dir / "cluster-info.json", {})
    clusters = cluster_info.get("clusters") or []
    if clusters:
        return clusters[0].get("name", "unknown-cluster")
    contexts = cluster_info.get("contexts") or []
    if contexts:
        return contexts[0].get("name", "unknown-cluster")
    return "unknown-cluster"


def build_report(control_library_dir: Path, evidence_dir: Path) -> dict[str, Any]:
    frameworks: dict[str, dict[str, Any]] = {}
    summary = {
        "total_controls": 0,
        "implemented": 0,
        "partial": 0,
        "planned": 0,
        "not_applicable": 0,
        "score_percent": 0.0,
    }

    weighted_total = 0.0
    weighted_denominator = 0

    for framework_key, filename in FRAMEWORK_FILES.items():
        payload = load_yaml(control_library_dir / filename)
        controls = payload.get("controls", [])
        score, counts = score_controls(controls)
        frameworks[framework_key] = {
            "score": round(score * 100.0, 2),
            "controls": controls,
        }

        summary["total_controls"] += counts["total_controls"]
        summary["implemented"] += counts["implemented"]
        summary["partial"] += counts["partial"]
        summary["planned"] += counts["planned"]
        summary["not_applicable"] += counts["not_applicable"]

        weighted_total += (
            counts["implemented"] * 1.0 + counts["partial"] * 0.5
        )
        weighted_denominator += counts["total_controls"] - counts["not_applicable"]

    overall_score = 0.0 if weighted_denominator <= 0 else (weighted_total / weighted_denominator)
    summary["score_percent"] = round(overall_score * 100.0, 2)

    report = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "cluster": extract_cluster_name(evidence_dir),
        "summary": summary,
        "frameworks": frameworks,
        "failing_automated_checks": collect_failing_checks(evidence_dir),
        "evidence_manifest": str(evidence_dir / "manifest.json"),
    }
    return report


def to_markdown(report: dict[str, Any]) -> str:
    lines: list[str] = []
    lines.append("# Compliance Report")
    lines.append("")
    lines.append(f"Generated at: {report['generated_at']}")
    lines.append(f"Cluster: {report['cluster']}")
    lines.append("")
    lines.append("## Summary")
    lines.append("")
    lines.append("| Metric | Value |")
    lines.append("|---|---|")
    for key, value in report["summary"].items():
        lines.append(f"| {key} | {value} |")
    lines.append("")
    lines.append("## Framework Scores")
    lines.append("")
    lines.append("| Framework | Score (%) | Controls |")
    lines.append("|---|---:|---:|")
    for framework, data in report["frameworks"].items():
        lines.append(f"| {framework} | {data['score']} | {len(data['controls'])} |")
    lines.append("")
    lines.append("## Failing Automated Checks")
    lines.append("")
    if report["failing_automated_checks"]:
        lines.append("| Tool | ID | Status | Description |")
        lines.append("|---|---|---|---|")
        for item in report["failing_automated_checks"]:
            lines.append(
                f"| {item.get('tool','')} | {item.get('id','')} | {item.get('status','')} | {str(item.get('description','')).replace('|','/')} |"
            )
    else:
        lines.append("No failing automated checks found in the provided evidence.")

    lines.append("")
    lines.append(f"Evidence manifest: {report['evidence_manifest']}")
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate compliance report from control libraries and collected evidence."
    )
    parser.add_argument(
        "--control-library-dir",
        default="secops/compliance/control-library",
        help="Directory containing SOC2, CIS, and ISO machine-readable control YAML files.",
    )
    parser.add_argument(
        "--evidence-dir",
        required=True,
        help="Evidence directory produced by collect-evidence.sh.",
    )
    parser.add_argument(
        "--format",
        choices=["json", "markdown"],
        default="json",
        help="Output format. json is default; markdown is human-readable.",
    )
    parser.add_argument(
        "--output",
        "-o",
        help="Optional output file path; defaults to stdout.",
    )
    parser.add_argument(
        "--fail-below",
        type=float,
        default=None,
        help="Exit code 1 when overall score (0-1) is below threshold; enables CI gating.",
    )
    args = parser.parse_args()

    control_library_dir = Path(args.control_library_dir)
    evidence_dir = Path(args.evidence_dir)
    report = build_report(control_library_dir, evidence_dir)

    output = (
        json.dumps(report, indent=2)
        if args.format == "json"
        else to_markdown(report)
    )

    if args.output:
        Path(args.output).write_text(output + ("\n" if not output.endswith("\n") else ""), encoding="utf-8")
    else:
        print(output)

    if args.fail_below is not None:
        overall = report["summary"]["score_percent"] / 100.0
        if overall < args.fail_below:
            print(
                f"Compliance score {overall:.4f} is below threshold {args.fail_below:.4f}",
                file=sys.stderr,
            )
            raise SystemExit(1)


if __name__ == "__main__":
    main()
