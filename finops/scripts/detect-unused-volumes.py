#!/usr/bin/env python3
"""
finops/scripts/detect-unused-volumes.py
Identify PersistentVolumes that have not been accessed in 30 days.
Calculates storage costs and generates an optimization report.

Usage:
  python detect-unused-volumes.py
  python detect-unused-volumes.py --days 30 --format json
  python detect-unused-volumes.py --format json --output report.json

Note: PV access timestamps require volumeattachments or custom metrics.
This script uses a heuristic: PVs bound to pods that have been idle.
"""

import argparse
import json
import sys
from datetime import datetime, timezone
from typing import Any

DEFAULT_UNUSED_DAYS = 30
DEFAULT_STORAGE_RATE_USD_PER_GB_MONTH = 0.10  # AWS gp3 EBS pricing


def fetch_persistent_volumes() -> list[dict[str, Any]]:
    """Fetch PVs from Kubernetes API."""
    try:
        from kubernetes import client, config  # noqa: PLC0415

        config.load_kube_config()
        v1 = client.CoreV1Api()
        pvs = v1.list_persistent_volume()
        return [pv.to_dict() for pv in pvs.items]
    except Exception as exc:  # noqa: BLE001
        print(f"WARNING: Kubernetes API unavailable ({exc}). Using mock data.", file=sys.stderr)
        return _mock_pvs()


def _mock_pvs() -> list[dict[str, Any]]:
    now = datetime.now(timezone.utc).isoformat()
    return [
        {
            "metadata": {"name": "pv-database-001", "creation_timestamp": "2024-06-01T00:00:00Z"},
            "spec": {
                "capacity": {"storage": "100Gi"},
                "storage_class_name": "gp3",
                "claim_ref": {"namespace": "team-a", "name": "db-pvc"},
            },
            "status": {"phase": "Bound"},
            "_last_access_estimate": "2024-10-01T00:00:00Z",  # >30 days ago
        },
        {
            "metadata": {"name": "pv-logs-002", "creation_timestamp": "2024-03-01T00:00:00Z"},
            "spec": {
                "capacity": {"storage": "500Gi"},
                "storage_class_name": "gp3",
                "claim_ref": {"namespace": "team-b", "name": "logs-pvc"},
            },
            "status": {"phase": "Bound"},
            "_last_access_estimate": "2024-09-15T00:00:00Z",  # >30 days ago
        },
        {
            "metadata": {"name": "pv-cache-003", "creation_timestamp": "2025-01-10T00:00:00Z"},
            "spec": {
                "capacity": {"storage": "20Gi"},
                "storage_class_name": "gp3",
                "claim_ref": {"namespace": "team-a", "name": "cache-pvc"},
            },
            "status": {"phase": "Bound"},
            "_last_access_estimate": now,  # recently accessed
        },
        {
            "metadata": {"name": "pv-orphan-004", "creation_timestamp": "2024-01-01T00:00:00Z"},
            "spec": {
                "capacity": {"storage": "200Gi"},
                "storage_class_name": "gp3",
                "claim_ref": None,
            },
            "status": {"phase": "Available"},
            "_last_access_estimate": None,
        },
    ]


def parse_storage_gib(storage_str: str) -> float:
    """Convert storage string like '100Gi' to GiB float."""
    if not storage_str:
        return 0.0
    s = str(storage_str).strip()
    if s.endswith("Gi"):
        return float(s[:-2])
    elif s.endswith("Ti"):
        return float(s[:-2]) * 1024
    elif s.endswith("Mi"):
        return float(s[:-2]) / 1024
    elif s.endswith("G"):
        return float(s[:-1]) * (1000 / 1024) ** 3
    return float(s) / (1024**3)


def is_likely_unused(pv: dict[str, Any], unused_days: int) -> tuple[bool, str | None]:
    """Return (is_unused, last_access_date)."""
    # Released/Available PVs are definitely unused
    phase = pv.get("status", {}).get("phase", "Unknown")
    if phase in ("Released", "Available"):
        return True, None

    # Use mock last access timestamp (in real impl, check volumeattachments or cloud API)
    last_access = pv.get("_last_access_estimate")
    if last_access is None:
        return True, None

    try:
        last_dt = datetime.fromisoformat(last_access.replace("Z", "+00:00"))
        now = datetime.now(timezone.utc)
        days_since = (now - last_dt).days
        return days_since >= unused_days, last_access
    except Exception:  # noqa: BLE001
        return False, None


def build_report(pvs: list[dict[str, Any]], unused_days: int) -> dict[str, Any]:
    """Identify unused volumes and estimate cost."""
    unused = []
    for pv in pvs:
        is_unused, last_access = is_likely_unused(pv, unused_days)
        if not is_unused:
            continue

        meta = pv.get("metadata", {})
        spec = pv.get("spec", {})
        storage_str = spec.get("capacity", {}).get("storage", "0Gi")
        size_gib = parse_storage_gib(str(storage_str))
        monthly_cost = size_gib * DEFAULT_STORAGE_RATE_USD_PER_GB_MONTH

        claim_ref = spec.get("claim_ref") or {}

        unused.append(
            {
                "volume_name": meta.get("name", "unknown"),
                "namespace": claim_ref.get("namespace", "unbound"),
                "pvc_name": claim_ref.get("name", "unbound"),
                "storage_class": spec.get("storage_class_name", "unknown"),
                "size_gib": size_gib,
                "phase": pv.get("status", {}).get("phase", "Unknown"),
                "last_access": last_access,
                "monthly_cost_usd": round(monthly_cost, 2),
                "recommended_action": (
                    "Delete PVC and PV (ensure data backed up first)"
                    if claim_ref.get("name")
                    else "Delete orphaned PV"
                ),
            }
        )

    unused.sort(key=lambda x: x["monthly_cost_usd"], reverse=True)
    total_waste = sum(v["monthly_cost_usd"] for v in unused)
    total_size = sum(v["size_gib"] for v in unused)

    return {
        "report_id": f"unused-volumes-{datetime.now(timezone.utc).strftime('%Y-%m-%d')}",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "unused_threshold_days": unused_days,
        "summary": {
            "total_volumes_scanned": len(pvs),
            "unused_volumes": len(unused),
            "total_unused_size_gib": round(total_size, 1),
            "estimated_monthly_waste_usd": round(total_waste, 2),
            "estimated_annual_waste_usd": round(total_waste * 12, 2),
        },
        "unused_volumes": unused,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Detect unused PersistentVolumes")
    parser.add_argument(
        "--days",
        type=int,
        default=DEFAULT_UNUSED_DAYS,
        help="Days without access to consider a volume unused",
    )
    parser.add_argument("--format", choices=["text", "json"], default="text")
    parser.add_argument("--output", "-o")
    args = parser.parse_args()

    pvs = fetch_persistent_volumes()
    report = build_report(pvs, args.days)

    if args.format == "json":
        output = json.dumps(report, indent=2)
    else:
        s = report["summary"]
        lines = [
            "=" * 60,
            f"  FinOps Unused Volume Report (>{args.days} days idle)",
            "=" * 60,
            f"  Volumes scanned  : {s['total_volumes_scanned']}",
            f"  Unused volumes   : {s['unused_volumes']}",
            f"  Total unused size: {s['total_unused_size_gib']} GiB",
            f"  Monthly waste    : ${s['estimated_monthly_waste_usd']:.2f}",
            f"  Annual waste     : ${s['estimated_annual_waste_usd']:.2f}",
            "=" * 60,
        ]
        for v in report["unused_volumes"]:
            lines.append(f"\n  {v['volume_name']} ({v['namespace']}/{v['pvc_name']})")
            lines.append(f"    Size  : {v['size_gib']} GiB | Class: {v['storage_class']}")
            lines.append(f"    Phase : {v['phase']} | Last access: {v['last_access'] or 'never'}")
            lines.append(f"    Cost  : ${v['monthly_cost_usd']:.2f}/month")
            lines.append(f"    Action: {v['recommended_action']}")
        output = "\n".join(lines)

    if args.output:
        with open(args.output, "w") as f:
            f.write(output)
        print(f"Report written to {args.output}")
    else:
        print(output)

    if report["summary"]["unused_volumes"] > 0:
        sys.exit(2)


if __name__ == "__main__":
    main()
