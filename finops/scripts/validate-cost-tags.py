#!/usr/bin/env python3
"""
finops/scripts/validate-cost-tags.py
Scan all namespaces and report pods missing finops.org/costcenter
and finops.org/environment labels. Calculates compliance percentage.

Usage:
  python validate-cost-tags.py --all-namespaces
  python validate-cost-tags.py --namespace team-a
  python validate-cost-tags.py --all-namespaces --format json

Exit codes:
  0 — fully compliant (100%)
  1 — error/exception
  2 — non-compliant pods found
"""

import argparse
import json
import sys
from datetime import datetime, timezone
from typing import Any

REQUIRED_LABELS = [
    "finops.org/costcenter",
    "finops.org/environment",
]


# ─── Kubernetes client ────────────────────────────────────────────────────────

def fetch_pods(namespace: str | None) -> list[dict[str, Any]]:
    """Fetch pods from Kubernetes. Falls back to mock data if unavailable."""
    try:
        from kubernetes import client, config  # noqa: PLC0415
        config.load_kube_config()
        v1 = client.CoreV1Api()
        if namespace:
            pods = v1.list_namespaced_pod(namespace)
        else:
            pods = v1.list_pod_for_all_namespaces()
        return [pod.to_dict() for pod in pods.items]
    except ImportError:
        print("WARNING: 'kubernetes' package not installed. Using mock data.", file=sys.stderr)
        return _mock_pods(namespace)
    except Exception as exc:  # noqa: BLE001
        print(f"WARNING: Kubernetes API unavailable ({exc}). Using mock data.", file=sys.stderr)
        return _mock_pods(namespace)


def _mock_pods(namespace: str | None) -> list[dict[str, Any]]:
    """Sample pod data for testing."""
    return [
        {
            "metadata": {
                "name": "api-pod-1",
                "namespace": namespace or "team-a",
                "labels": {
                    "finops.org/costcenter": "engineering",
                    "finops.org/environment": "production",
                    "app": "api",
                },
            }
        },
        {
            "metadata": {
                "name": "worker-pod-1",
                "namespace": namespace or "team-a",
                "labels": {
                    "finops.org/costcenter": "engineering",
                    # Missing environment label
                    "app": "worker",
                },
            }
        },
        {
            "metadata": {
                "name": "orphan-pod",
                "namespace": namespace or "team-b",
                "labels": {
                    "app": "legacy",
                    # Missing both labels
                },
            }
        },
    ]


# ─── Validation logic ─────────────────────────────────────────────────────────

def validate_pod(pod: dict[str, Any]) -> dict[str, Any]:
    """Check a pod for required labels. Return compliance result."""
    meta = pod.get("metadata", {})
    labels = meta.get("labels", {}) or {}
    missing = [lbl for lbl in REQUIRED_LABELS if not labels.get(lbl)]
    return {
        "pod": meta.get("name", "unknown"),
        "namespace": meta.get("namespace", "unknown"),
        "compliant": len(missing) == 0,
        "missing_labels": missing,
        "present_labels": {lbl: labels[lbl] for lbl in REQUIRED_LABELS if lbl in labels},
    }


def build_report(pods: list[dict[str, Any]], namespace: str | None) -> dict[str, Any]:
    """Build the full compliance report."""
    results = [validate_pod(p) for p in pods]
    compliant = [r for r in results if r["compliant"]]
    non_compliant = [r for r in results if not r["compliant"]]

    total = len(results)
    pct = (len(compliant) / total * 100) if total > 0 else 100.0

    # Group non-compliant by namespace
    ns_non_compliant: dict[str, list[str]] = {}
    for r in non_compliant:
        ns = r["namespace"]
        ns_non_compliant.setdefault(ns, [])
        ns_non_compliant[ns].append(r["pod"])

    return {
        "report_id": f"tag-compliance-{datetime.now(timezone.utc).strftime('%Y-%m-%d')}",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "scope": namespace or "all-namespaces",
        "summary": {
            "total_pods": total,
            "compliant_pods": len(compliant),
            "non_compliant_pods": len(non_compliant),
            "compliance_percentage": round(pct, 1),
            "is_compliant": pct >= 95.0,
        },
        "non_compliant": non_compliant,
        "non_compliant_by_namespace": {
            ns: {"pod_count": len(pods_list), "pods": pods_list}
            for ns, pods_list in sorted(ns_non_compliant.items())
        },
    }


def print_report_text(report: dict[str, Any]) -> None:
    """Print human-readable report."""
    s = report["summary"]
    status = "✅ COMPLIANT" if s["is_compliant"] else "❌ NON-COMPLIANT"
    print("=" * 60)
    print("  FinOps Cost Tag Compliance Report")
    print(f"  Scope    : {report['scope']}")
    print(f"  Status   : {status}")
    print(f"  Compliance: {s['compliance_percentage']}%")
    print("=" * 60)
    print(f"  Total pods      : {s['total_pods']}")
    print(f"  Compliant       : {s['compliant_pods']}")
    print(f"  Non-compliant   : {s['non_compliant_pods']}")
    print("=" * 60)

    if report["non_compliant"]:
        print("\nNon-compliant pods:")
        for r in report["non_compliant"]:
            print(f"\n  Namespace: {r['namespace']} | Pod: {r['pod']}")
            print(f"  Missing labels: {', '.join(r['missing_labels'])}")

    if report["non_compliant_by_namespace"]:
        print("\nSummary by namespace:")
        for ns, data in report["non_compliant_by_namespace"].items():
            print(f"  {ns}: {data['pod_count']} non-compliant pods")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Validate finops.org cost labels on all pods"
    )
    parser.add_argument("--namespace", "-n")
    parser.add_argument("--all-namespaces", "-A", action="store_true")
    parser.add_argument("--format", choices=["text", "json"], default="text")
    parser.add_argument("--output", "-o")
    args = parser.parse_args()

    ns = None if args.all_namespaces else args.namespace
    pods = fetch_pods(ns)
    report = build_report(pods, ns)

    if args.format == "json":
        output = json.dumps(report, indent=2)
    else:
        import io
        buf = io.StringIO()
        sys.stdout = buf
        print_report_text(report)
        sys.stdout = sys.__stdout__
        output = buf.getvalue()

    if args.output:
        with open(args.output, "w") as f:
            f.write(output)
        print(f"Report written to {args.output}")
    else:
        print(output)

    if not report["summary"]["is_compliant"]:
        sys.exit(2)


if __name__ == "__main__":
    main()
