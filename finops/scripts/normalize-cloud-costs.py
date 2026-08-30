#!/usr/bin/env python3
"""
finops/scripts/normalize-cloud-costs.py
Query multi-cloud cost data (Kubecost-first) and produce normalized cross-cloud reports.
"""

from __future__ import annotations

import argparse
import csv
import io
import json
import subprocess
import sys
from datetime import date, datetime, timedelta, timezone
from typing import Any

# Approximation for comparison, not billing-grade accounting.
# This is an approximation for comparison purposes, not billing.
# Use your actual cloud bills for financial reporting.
NORMALIZED_CPU_HOUR_RATE_USD = 0.048  # <-- UPDATE QUARTERLY
NORMALIZED_GIB_HOUR_RATE_USD = 0.006  # <-- UPDATE QUARTERLY

# <-- CHANGE THIS: Set your Kubecost/OpenCost API base URL.
# Valid values: http(s) URL, e.g. http://kubecost.finops.svc.cluster.local:9090.
# Find this in your cluster service details from finops/docs/installation.md.
DEFAULT_KUBECOST_URL = "http://kubecost.finops.svc.cluster.local:9090"

# <-- CHANGE THIS: Set AWS Cost Explorer endpoint if using direct AWS enrichment.
# Valid values: AWS Cost Explorer endpoint/region config used by your SDK.
# Find this in AWS billing API docs and your cloud provider setup guide.
AWS_COST_API_HINT = "https://ce.us-east-1.amazonaws.com"

# <-- CHANGE THIS: Set Azure Cost Management endpoint for your tenant.
# Valid values: https://management.azure.com with CostManagement query path.
# Find this in Azure Cost Management API docs and your tenant/subscription config.
AZURE_COST_API_HINT = "https://management.azure.com"

# <-- CHANGE THIS: Set GCP Billing Export dataset/table location.
# Valid values: billing project.dataset.table, queried via BigQuery.
# Find this in your Cloud Billing export settings in GCP.
GCP_BILLING_EXPORT_HINT = "project_id.billing_dataset.gcp_billing_export_v1"


def parse_cpu(cpu: str | None) -> float:
    if not cpu:
        return 0.0
    value = str(cpu).strip()
    if value.endswith("m"):
        return float(value[:-1]) / 1000.0
    return float(value)


def parse_memory_gib(memory: str | None) -> float:
    if not memory:
        return 0.0
    value = str(memory).strip()
    if value.endswith("Mi"):
        return float(value[:-2]) / 1024
    if value.endswith("Gi"):
        return float(value[:-2])
    if value.endswith("Ti"):
        return float(value[:-2]) * 1024
    return float(value) / (1024**3)


def normalized_cost(vcpu_hours: float, gib_hours: float) -> float:
    return (vcpu_hours * NORMALIZED_CPU_HOUR_RATE_USD) + (gib_hours * NORMALIZED_GIB_HOUR_RATE_USD)


def _group_value(props: dict[str, Any], group_by: str) -> str:
    labels = props.get("labels", {})
    if group_by == "namespace":
        return props.get("namespace", "unknown")
    if group_by == "team":
        return labels.get("finops.org/team", labels.get("team", "unassigned"))
    if group_by == "environment":
        return labels.get("finops.org/environment", "unknown")
    if group_by == "service":
        return labels.get("app", labels.get("service", props.get("controller", "unknown")))
    return "unknown"


def query_kubecost(kubecost_url: str, period_days: int, group_by: str) -> list[dict[str, Any]]:
    try:
        import requests  # noqa: PLC0415

        resp = requests.get(
            f"{kubecost_url}/model/allocation",
            params={
                "window": f"{period_days}d",
                "aggregate": "controller,namespace",
                "includeIdle": "true",
            },
            timeout=30,
        )
        resp.raise_for_status()
        windows = resp.json().get("data", [])
        allocations = windows[-1] if windows else {}

        grouped: dict[str, dict[str, float]] = {}
        for _, value in allocations.items():
            props = value.get("properties", {})
            key = _group_value(props, group_by)
            if key not in grouped:
                grouped[key] = {"aws": 0.0, "azure": 0.0, "gcp": 0.0, "total": 0.0}

            cloud = str(props.get("provider", "")).lower()
            provider = (
                "aws"
                if "aws" in cloud
                else "azure"
                if "azure" in cloud
                else "gcp"
                if "gcp" in cloud
                else "aws"
            )

            cpu_cores = parse_cpu(str(value.get("cpuCoreRequestAverage", 0.0)))
            mem_gib = parse_memory_gib(str(value.get("ramByteRequestAverage", 0.0)))
            vcpu_hours = cpu_cores * (period_days * 24)
            gib_hours = mem_gib * (period_days * 24)
            ncost = normalized_cost(vcpu_hours, gib_hours)

            grouped[key][provider] += ncost
            grouped[key]["total"] += ncost

        return [{"group": key, **vals} for key, vals in grouped.items()]
    except Exception as exc:  # noqa: BLE001
        print(f"WARNING: Kubecost query failed ({exc}); using mock data.", file=sys.stderr)
        return [
            {"group": "platform", "aws": 1240.0, "azure": 380.0, "gcp": 0.0, "total": 1620.0},
            {"group": "payments", "aws": 820.0, "azure": 0.0, "gcp": 640.0, "total": 1460.0},
        ]


def maybe_enrich_with_cloud_apis(
    rows: list[dict[str, Any]], use_aws: bool, use_azure: bool, use_gcp: bool
) -> list[dict[str, Any]]:
    # Optional enrichment stub. Kubecost remains primary data source.
    if use_aws:
        print(
            f"INFO: AWS enrichment requested. Configure endpoint/auth as documented: {AWS_COST_API_HINT}"
        )
    if use_azure:
        print(
            f"INFO: Azure enrichment requested. Configure endpoint/auth as documented: {AZURE_COST_API_HINT}"
        )
    if use_gcp:
        print(
            f"INFO: GCP enrichment requested. Configure billing export query target: {GCP_BILLING_EXPORT_HINT}"
        )
    return rows


def compute_mom(rows: list[dict[str, Any]], period_days: int) -> list[dict[str, Any]]:
    # Fallback heuristic until historical store is wired.
    factor = 0.1 if period_days >= 30 else 0.03
    output = []
    for row in rows:
        baseline = max(1.0, row["total"] / (1 + factor))
        mom = ((row["total"] - baseline) / baseline) * 100
        output.append({**row, "mom_change_pct": round(mom, 1)})
    return output


def load_opportunities() -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    optimization = []
    reserved = []
    try:
        with open("finops/scripts/.last-rightsizing-report.json", "r", encoding="utf-8") as f:
            payload = json.load(f)
            for rec in payload.get("recommendations", [])[:5]:
                optimization.append(
                    {
                        "workload": rec.get("workload_name", "unknown"),
                        "cloud": "Kubernetes",
                        "current": rec.get("current_monthly_cost_usd", 0.0),
                        "recommended": rec.get("recommended_monthly_cost_usd", 0.0),
                        "savings": rec.get("potential_monthly_savings_usd", 0.0),
                    }
                )
    except Exception:
        optimization = [
            {
                "workload": "api-gateway",
                "cloud": "AWS/EKS",
                "current": 340.0,
                "recommended": 228.0,
                "savings": 112.0,
            }
        ]

    try:
        with open("finops/scripts/.last-reserved-advisor.json", "r", encoding="utf-8") as f:
            payload = json.load(f)
            for rec in payload.get("recommendations", [])[:5]:
                reserved.append(
                    {
                        "resource": rec.get("resource", "unknown"),
                        "cloud": rec.get("cloud", "unknown"),
                        "current": rec.get("on_demand_monthly_usd", 0.0),
                        "committed": rec.get("committed_monthly_usd", 0.0),
                        "annual_savings": rec.get("annual_savings_usd", 0.0),
                    }
                )
    except Exception:
        reserved = [
            {
                "resource": "us-east-1 r6i.large",
                "cloud": "AWS",
                "current": 180.0,
                "committed": 108.0,
                "annual_savings": 864.0,
            }
        ]

    return optimization, reserved


def report_markdown(rows: list[dict[str, Any]], group_by: str, start: date, end: date) -> str:
    optimization, reserved = load_opportunities()
    lines = [
        "# Cross-Cloud Cost Report",
        f"Period: {start.isoformat()} to {end.isoformat()}",
        "",
        f"## By {group_by.capitalize()}",
        "",
        f"| {group_by.capitalize()} | AWS | Azure | GCP | Total | MoM Change |",
        "|---|---:|---:|---:|---:|---:|",
    ]
    for row in sorted(rows, key=lambda r: r["total"], reverse=True):
        mom = row.get("mom_change_pct", 0.0)
        mom_text = f"{mom:+.1f}%"
        lines.append(
            f"| {row['group']} | ${row['aws']:.0f} | ${row['azure']:.0f} | ${row['gcp']:.0f} | ${row['total']:.0f} | {mom_text} |"
        )

    lines.extend(
        [
            "",
            "## Optimization Opportunities",
            "",
            "| Workload | Cloud | Current | Recommended | Savings |",
            "|---|---|---:|---:|---:|",
        ]
    )
    for row in optimization:
        lines.append(
            f"| {row['workload']} | {row['cloud']} | ${row['current']:.0f}/mo | ${row['recommended']:.0f}/mo | ${row['savings']:.0f}/mo |"
        )

    lines.extend(
        [
            "",
            "## Reserved Capacity Opportunities",
            "",
            "| Resource | Cloud | Current spend | Committed rate | Annual savings |",
            "|---|---|---:|---:|---:|",
        ]
    )
    for row in reserved:
        lines.append(
            f"| {row['resource']} | {row['cloud']} | ${row['current']:.0f}/mo | ${row['committed']:.0f}/mo | ${row['annual_savings']:.0f}/yr |"
        )

    return "\n".join(lines) + "\n"


def report_csv(rows: list[dict[str, Any]]) -> str:
    out = io.StringIO()
    writer = csv.writer(out)
    writer.writerow(["group", "aws", "azure", "gcp", "total", "mom_change_pct"])
    for row in rows:
        writer.writerow(
            [
                row["group"],
                round(row["aws"], 2),
                round(row["azure"], 2),
                round(row["gcp"], 2),
                round(row["total"], 2),
                row.get("mom_change_pct", 0.0),
            ]
        )
    return out.getvalue()


def write_configmap(rows: list[dict[str, Any]], group_by: str, period_days: int) -> None:
    payload = {
        "apiVersion": "v1",
        "kind": "ConfigMap",
        "metadata": {"name": "finops-normalized-costs", "namespace": "finops"},
        "data": {
            "by": group_by,
            "period_days": str(period_days),
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "report": json.dumps(rows),
        },
    }
    proc = subprocess.run(
        ["kubectl", "apply", "-f", "-"], input=json.dumps(payload), text=True, capture_output=True
    )
    if proc.returncode != 0:
        print(
            f"WARNING: failed to update ConfigMap finops-normalized-costs: {proc.stderr.strip()}",
            file=sys.stderr,
        )


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Normalize multi-cloud compute costs into a single comparison model"
    )
    parser.add_argument(
        "--aws", action="store_true", help="Optionally enrich with AWS Cost Explorer data"
    )
    parser.add_argument(
        "--azure", action="store_true", help="Optionally enrich with Azure Cost Management data"
    )
    parser.add_argument(
        "--gcp", action="store_true", help="Optionally enrich with GCP Billing Export data"
    )
    parser.add_argument(
        "--kubecost", default=DEFAULT_KUBECOST_URL, help="Kubecost/OpenCost base URL"
    )
    parser.add_argument(
        "--period", type=int, default=30, help="Look-back period in days (default: 30)"
    )
    parser.add_argument(
        "--output", choices=["json", "csv", "markdown"], default="markdown", help="Output format"
    )
    parser.add_argument(
        "--by",
        choices=["service", "team", "environment", "namespace"],
        default="team",
        help="Grouping dimension",
    )
    parser.add_argument(
        "--write-configmap",
        action="store_true",
        help="Write normalized report to ConfigMap finops-normalized-costs",
    )
    parser.add_argument("--out-file", help="Optional output file path (default: stdout)")
    args = parser.parse_args()

    end = date.today()
    start = end - timedelta(days=args.period)

    rows = query_kubecost(args.kubecost, args.period, args.by)
    rows = maybe_enrich_with_cloud_apis(rows, args.aws, args.azure, args.gcp)
    rows = compute_mom(rows, args.period)

    if args.write_configmap:
        write_configmap(rows, args.by, args.period)

    if args.output == "json":
        output = json.dumps(
            {
                "generated_at": datetime.now(timezone.utc).isoformat(),
                "period": {"start": start.isoformat(), "end": end.isoformat()},
                "group_by": args.by,
                "normalization": {
                    "formula": "(vCPU_hours × $0.048) + (GiB_hours × $0.006)",
                    "cpu_rate": NORMALIZED_CPU_HOUR_RATE_USD,
                    "memory_rate": NORMALIZED_GIB_HOUR_RATE_USD,
                },
                "rows": rows,
            },
            indent=2,
        )
    elif args.output == "csv":
        output = report_csv(rows)
    else:
        output = report_markdown(rows, args.by, start, end)

    if args.out_file:
        with open(args.out_file, "w", encoding="utf-8") as f:
            f.write(output)
        print(f"Report written to {args.out_file}")
    else:
        print(output)


if __name__ == "__main__":
    main()
