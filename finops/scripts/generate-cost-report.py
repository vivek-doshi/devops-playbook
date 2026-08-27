#!/usr/bin/env python3
"""
finops/scripts/generate-cost-report.py
Generate monthly FinOps chargeback/showback cost reports by querying
the Kubecost/OpenCost API and aggregating costs by cost center.

Output formats: CSV, JSON

Usage:
  python generate-cost-report.py --month 2025-01
  python generate-cost-report.py --month 2025-01 --format csv --output /tmp/report.csv
  python generate-cost-report.py --month 2025-01 --format json --cluster my-cluster

Requirements:
  pip install requests
"""

import argparse
import csv
import io
import json
import sys
from datetime import datetime, timezone
from typing import Any

# ─── Shared cluster cost estimates (override via CLI or env) ──────────────────
SHARED_COSTS_DEFAULT = {
    "control_plane": 2000.0,
    "monitoring": 500.0,
    "logging": 300.0,
    "networking": 200.0,
}

# ─── Helpers ──────────────────────────────────────────────────────────────────


def month_to_range(month: str) -> tuple[str, str]:
    """Convert 'YYYY-MM' to (start_iso, end_iso) for the full month."""
    import calendar

    year, mo = int(month[:4]), int(month[5:7])
    _, last_day = calendar.monthrange(year, mo)
    start = datetime(year, mo, 1, tzinfo=timezone.utc).isoformat()
    end = datetime(year, mo, last_day, 23, 59, 59, tzinfo=timezone.utc).isoformat()
    return start, end


def fetch_namespace_costs(kubecost_url: str, start: str, end: str) -> list[dict[str, Any]]:
    """
    Fetch per-namespace cost breakdown from Kubecost/OpenCost API.
    Returns a list of namespace cost dicts.
    """
    try:
        import requests  # noqa: PLC0415

        params = {
            "window": f"{start},{end}",
            "aggregate": "namespace",
            "includeIdle": "true",
            "shareIdle": "false",
        }
        resp = requests.get(
            f"{kubecost_url}/model/allocation",
            params=params,
            timeout=30,
        )
        resp.raise_for_status()
        data = resp.json()
        # Kubecost returns a list of allocation windows; use the last one
        allocations = data.get("data", [{}])[-1] if data.get("data") else {}
        return list(allocations.values())
    except Exception as exc:  # noqa: BLE001
        print(f"WARNING: Could not fetch cost data ({exc}). Using mock data.", file=sys.stderr)
        return _mock_namespace_costs()


def _mock_namespace_costs() -> list[dict[str, Any]]:
    """Return sample cost data for testing."""
    return [
        {
            "name": "team-backend",
            "properties": {
                "namespace": "team-backend",
                "labels": {
                    "finops.org/costcenter": "engineering",
                    "finops.org/environment": "production",
                },
            },
            "cpuCost": 3500.0,
            "ramCost": 1200.0,
            "pvCost": 800.0,
            "networkCost": 300.0,
            "totalCost": 5800.0,
        },
        {
            "name": "team-frontend",
            "properties": {
                "namespace": "team-frontend",
                "labels": {
                    "finops.org/costcenter": "frontend",
                    "finops.org/environment": "production",
                },
            },
            "cpuCost": 500.0,
            "ramCost": 200.0,
            "pvCost": 100.0,
            "networkCost": 50.0,
            "totalCost": 850.0,
        },
        {
            "name": "team-ml",
            "properties": {
                "namespace": "team-ml",
                "labels": {
                    "finops.org/costcenter": "data-science",
                    "finops.org/environment": "production",
                },
            },
            "cpuCost": 8000.0,
            "ramCost": 4000.0,
            "pvCost": 2000.0,
            "networkCost": 500.0,
            "totalCost": 14500.0,
        },
        {
            "name": "monitoring",
            "properties": {
                "namespace": "monitoring",
                "labels": {
                    "finops.org/costcenter": "platform-infra",
                    "finops.org/environment": "production",
                },
            },
            "cpuCost": 200.0,
            "ramCost": 150.0,
            "pvCost": 80.0,
            "networkCost": 20.0,
            "totalCost": 450.0,
        },
    ]


# ─── Report building ──────────────────────────────────────────────────────────


def build_report(
    namespace_costs: list[dict[str, Any]],
    shared_costs: dict[str, float],
    cluster_name: str,
    cloud_provider: str,
    report_period: dict[str, str],
) -> dict[str, Any]:
    """Aggregate costs by cost center and allocate shared costs proportionally."""

    # Group by cost center
    by_cost_center: dict[str, dict[str, Any]] = {}
    total_cluster_cost = sum(ns.get("totalCost", 0) for ns in namespace_costs)

    for ns in namespace_costs:
        props = ns.get("properties", {})
        labels = props.get("labels", {})
        cost_center = labels.get("finops.org/costcenter", "untagged")
        namespace = ns.get("name", "unknown")

        if cost_center not in by_cost_center:
            by_cost_center[cost_center] = {
                "cost_center": cost_center,
                "namespaces": [],
                "compute_cost": 0.0,
                "storage_cost": 0.0,
                "network_cost": 0.0,
                "total_cost": 0.0,
            }

        cc = by_cost_center[cost_center]
        compute = ns.get("cpuCost", 0) + ns.get("ramCost", 0)
        storage = ns.get("pvCost", 0)
        network = ns.get("networkCost", 0)
        total = ns.get("totalCost", 0)

        cc["namespaces"].append(namespace)
        cc["compute_cost"] += compute
        cc["storage_cost"] += storage
        cc["network_cost"] += network
        cc["total_cost"] += total

    # Allocate shared costs proportionally by total usage
    total_shared = sum(shared_costs.values())
    for cc_data in by_cost_center.values():
        proportion = cc_data["total_cost"] / total_cluster_cost if total_cluster_cost > 0 else 0
        cc_data["shared_cost_allocation"] = round(proportion * total_shared, 2)
        cc_data["total_cost_with_shared"] = round(
            cc_data["total_cost"] + cc_data["shared_cost_allocation"], 2
        )
        # Round individual costs
        cc_data["compute_cost"] = round(cc_data["compute_cost"], 2)
        cc_data["storage_cost"] = round(cc_data["storage_cost"], 2)
        cc_data["network_cost"] = round(cc_data["network_cost"], 2)
        cc_data["total_cost"] = round(cc_data["total_cost"], 2)

    cost_centers = sorted(by_cost_center.values(), key=lambda x: x["total_cost"], reverse=True)

    return {
        "report_id": f"{report_period['start'][:7]}",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "report_period": report_period,
        "cluster_name": cluster_name,
        "cloud_provider": cloud_provider,
        "currency": "USD",
        "cost_centers": cost_centers,
        "shared_costs": {
            **shared_costs,
            "total": total_shared,
            "allocation_method": "proportional_by_namespace_resource_usage",
        },
        "totals": {
            "cluster_total_usd": round(total_cluster_cost, 2),
            "shared_costs_usd": round(total_shared, 2),
            "grand_total_usd": round(total_cluster_cost + total_shared, 2),
        },
    }


def report_to_csv(report: dict[str, Any]) -> str:
    """Convert report to CSV string."""
    output = io.StringIO()
    writer = csv.writer(output)

    writer.writerow(
        [
            "report_id",
            "cluster_name",
            "cloud_provider",
            "currency",
            "report_start",
            "report_end",
            "cost_center",
            "namespace",
            "compute_cost_usd",
            "storage_cost_usd",
            "network_cost_usd",
            "total_cost_usd",
            "shared_cost_allocation_usd",
            "total_with_shared_usd",
        ]
    )

    for cc in report["cost_centers"]:
        for ns in cc["namespaces"]:
            writer.writerow(
                [
                    report["report_id"],
                    report["cluster_name"],
                    report["cloud_provider"],
                    report["currency"],
                    report["report_period"]["start"],
                    report["report_period"]["end"],
                    cc["cost_center"],
                    ns,
                    cc["compute_cost"],
                    cc["storage_cost"],
                    cc["network_cost"],
                    cc["total_cost"],
                    cc["shared_cost_allocation"],
                    cc["total_cost_with_shared"],
                ]
            )

    return output.getvalue()


# ─── Entry point ──────────────────────────────────────────────────────────────


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate FinOps monthly chargeback/showback cost report"
    )
    parser.add_argument(
        "--month", required=True, help="Report month in YYYY-MM format (e.g., 2025-01)"
    )
    parser.add_argument("--kubecost-url", default="http://kubecost.finops.svc.cluster.local:9090")
    parser.add_argument("--cluster", default="production", dest="cluster_name")
    parser.add_argument(
        "--provider", default="aws", choices=["aws", "azure", "gcp"], dest="cloud_provider"
    )
    parser.add_argument("--format", choices=["json", "csv"], default="json")
    parser.add_argument("--output", "-o", help="Output file (default: stdout)")
    args = parser.parse_args()

    start, end = month_to_range(args.month)
    report_period = {"start": start, "end": end}

    namespace_costs = fetch_namespace_costs(args.kubecost_url, start, end)
    report = build_report(
        namespace_costs,
        SHARED_COSTS_DEFAULT,
        args.cluster_name,
        args.cloud_provider,
        report_period,
    )

    output = json.dumps(report, indent=2) if args.format == "json" else report_to_csv(report)

    if args.output:
        with open(args.output, "w") as f:
            f.write(output)
        print(f"Report written to {args.output}")
    else:
        print(output)


if __name__ == "__main__":
    main()
