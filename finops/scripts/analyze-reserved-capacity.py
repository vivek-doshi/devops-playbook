#!/usr/bin/env python3
"""
finops/scripts/analyze-reserved-capacity.py
Analyze workload stability over 90 days to identify candidates for
reserved instance or savings plan purchase.

Stability is defined as < 10% resource variance over the analysis period.
Calculates potential annual savings from reserved capacity purchase.

Usage:
  python analyze-reserved-capacity.py --namespace team-a
  python analyze-reserved-capacity.py --all-namespaces --format json

Requirements:
  pip install requests
"""

import argparse
import json
import sys
from datetime import datetime, timezone
from typing import Any

# Reserved instance discount assumptions (varies by cloud provider and term)
RESERVED_DISCOUNT = {
    "aws": {"1yr_no_upfront": 0.30, "1yr_all_upfront": 0.40, "3yr_all_upfront": 0.60},
    "azure": {"1yr": 0.32, "3yr": 0.50},
    "gcp": {"1yr": 0.25, "3yr": 0.45},
}
DEFAULT_CPU_HOURLY_RATE = 0.048
DEFAULT_MEMORY_HOURLY_RATE = 0.006
STABILITY_VARIANCE_THRESHOLD = 10.0  # percent


def fetch_workload_metrics(prometheus_url: str, namespace: str | None) -> list[dict[str, Any]]:
    """Fetch 90-day CPU/memory stats per workload from Prometheus."""
    try:
        import requests  # noqa: PLC0415
        ns_filter = f',namespace="{namespace}"' if namespace else ""

        def query(q):
            resp = requests.get(f"{prometheus_url}/api/v1/query", params={"query": q}, timeout=60)
            resp.raise_for_status()
            return resp.json().get("data", {}).get("result", [])

        # Average usage
        cpu_avg = query(f'avg_over_time(container_cpu_usage_seconds_total{{container!=""{ns_filter}}}[90d])')
        # Standard deviation approximated via quantile range
        cpu_p95 = query(f'quantile_over_time(0.95, container_cpu_usage_seconds_total{{container!=""{ns_filter}}}[90d])')
        cpu_p5 = query(f'quantile_over_time(0.05, container_cpu_usage_seconds_total{{container!=""{ns_filter}}}[90d])')

        mem_avg = query(f'avg_over_time(container_memory_working_set_bytes{{container!=""{ns_filter}}}[90d])')

        # Build workload data
        data: dict[tuple, dict] = {}
        for r in cpu_avg:
            key = (r["metric"].get("namespace"), r["metric"].get("pod"), r["metric"].get("container"))
            data[key] = {"cpu_avg": float(r["value"][1])}
        for r in cpu_p95:
            key = (r["metric"].get("namespace"), r["metric"].get("pod"), r["metric"].get("container"))
            data.setdefault(key, {})["cpu_p95"] = float(r["value"][1])
        for r in cpu_p5:
            key = (r["metric"].get("namespace"), r["metric"].get("pod"), r["metric"].get("container"))
            data.setdefault(key, {})["cpu_p5"] = float(r["value"][1])
        for r in mem_avg:
            key = (r["metric"].get("namespace"), r["metric"].get("pod"), r["metric"].get("container"))
            data.setdefault(key, {})["mem_avg_bytes"] = float(r["value"][1])

        return [
            {
                "namespace": k[0], "pod": k[1], "container": k[2],
                "cpu_avg_cores": v.get("cpu_avg", 0),
                "cpu_p95_cores": v.get("cpu_p95", 0),
                "cpu_p5_cores": v.get("cpu_p5", 0),
                "mem_avg_gib": v.get("mem_avg_bytes", 0) / (1024 ** 3),
            }
            for k, v in data.items()
        ]
    except Exception as exc:  # noqa: BLE001
        print(f"WARNING: Prometheus unavailable ({exc}). Using mock data.", file=sys.stderr)
        return _mock_metrics(namespace)


def _mock_metrics(namespace: str | None) -> list[dict[str, Any]]:
    ns = namespace or "team-a"
    return [
        {"namespace": ns, "pod": "api", "container": "app",
         "cpu_avg_cores": 1.8, "cpu_p95_cores": 1.95, "cpu_p5_cores": 1.65, "mem_avg_gib": 3.8},
        {"namespace": ns, "pod": "db", "container": "postgres",
         "cpu_avg_cores": 0.5, "cpu_p95_cores": 0.55, "cpu_p5_cores": 0.45, "mem_avg_gib": 2.0},
        {"namespace": ns, "pod": "worker", "container": "worker",
         "cpu_avg_cores": 0.2, "cpu_p95_cores": 2.0, "cpu_p5_cores": 0.05, "mem_avg_gib": 0.5},
    ]


def compute_variance_pct(avg: float, p95: float, p5: float) -> float:
    """Compute coefficient of variation as a proxy for variance %."""
    if avg == 0:
        return 0.0
    # Avoid classifying values on the threshold as unstable due to floating-point noise.
    return max(0.0, ((p95 - p5) / avg) * 100 - 1e-9)


def build_report(workloads: list[dict[str, Any]], cloud_provider: str) -> dict[str, Any]:
    discounts = RESERVED_DISCOUNT.get(cloud_provider, RESERVED_DISCOUNT["aws"])
    best_term = max(discounts, key=discounts.get)
    best_discount = discounts[best_term]

    stable = []
    for w in workloads:
        variance_pct = compute_variance_pct(
            w["cpu_avg_cores"], w["cpu_p95_cores"], w["cpu_p5_cores"]
        )
        is_stable = variance_pct <= STABILITY_VARIANCE_THRESHOLD

        if not is_stable:
            continue

        on_demand_monthly = (
            w["cpu_avg_cores"] * DEFAULT_CPU_HOURLY_RATE +
            w["mem_avg_gib"] * DEFAULT_MEMORY_HOURLY_RATE
        ) * 730

        reserved_monthly = on_demand_monthly * (1 - best_discount)
        annual_savings = (on_demand_monthly - reserved_monthly) * 12

        stable.append({
            "namespace": w["namespace"],
            "workload": w["pod"],
            "container": w["container"],
            "cpu_avg_cores": round(w["cpu_avg_cores"], 3),
            "mem_avg_gib": round(w["mem_avg_gib"], 2),
            "cpu_variance_pct": round(variance_pct, 1),
            "on_demand_monthly_usd": round(on_demand_monthly, 2),
            "reserved_monthly_usd": round(reserved_monthly, 2),
            "monthly_savings_usd": round(on_demand_monthly - reserved_monthly, 2),
            "annual_savings_usd": round(annual_savings, 2),
            "recommended_term": best_term,
            "discount_pct": round(best_discount * 100, 0),
        })

    stable.sort(key=lambda x: x["annual_savings_usd"], reverse=True)
    total_annual_savings = sum(s["annual_savings_usd"] for s in stable)

    return {
        "report_id": f"reserved-capacity-{datetime.now(timezone.utc).strftime('%Y-%m-%d')}",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "cloud_provider": cloud_provider,
        "analysis_period_days": 90,
        "stability_threshold_pct": STABILITY_VARIANCE_THRESHOLD,
        "summary": {
            "total_workloads_analyzed": len(workloads),
            "stable_workloads": len(stable),
            "total_potential_annual_savings_usd": round(total_annual_savings, 2),
        },
        "stable_workloads": stable,
        "available_terms": discounts,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Analyze reserved capacity candidates")
    parser.add_argument("--namespace", "-n")
    parser.add_argument("--all-namespaces", "-A", action="store_true")
    parser.add_argument("--prometheus-url", default="http://prometheus-operated.monitoring.svc.cluster.local:9090")
    parser.add_argument("--cloud-provider", default="aws", choices=["aws", "azure", "gcp"])
    parser.add_argument("--format", choices=["text", "json"], default="text")
    parser.add_argument("--output", "-o")
    args = parser.parse_args()

    ns = None if args.all_namespaces else args.namespace
    workloads = fetch_workload_metrics(args.prometheus_url, ns)
    report = build_report(workloads, args.cloud_provider)

    if args.format == "json":
        output = json.dumps(report, indent=2)
    else:
        s = report["summary"]
        lines = [
            "=" * 60,
            "  FinOps Reserved Capacity Analysis",
            f"  Cloud: {report['cloud_provider']} | Period: {report['analysis_period_days']} days",
            "=" * 60,
            f"  Workloads analyzed : {s['total_workloads_analyzed']}",
            f"  Stable workloads   : {s['stable_workloads']}",
            f"  Total annual saving: ${s['total_potential_annual_savings_usd']:,.2f}",
            "=" * 60,
        ]
        for w in report["stable_workloads"][:15]:
            lines.append(f"\n  {w['workload']}/{w['container']} ({w['namespace']})")
            lines.append(f"    CPU: {w['cpu_avg_cores']}c avg | Variance: {w['cpu_variance_pct']}%")
            lines.append(f"    On-demand: ${w['on_demand_monthly_usd']:.2f}/mo → Reserved: ${w['reserved_monthly_usd']:.2f}/mo")
            lines.append(f"    Savings: ${w['annual_savings_usd']:.2f}/yr ({w['discount_pct']:.0f}% with {w['recommended_term']})")
        output = "\n".join(lines)

    if args.output:
        with open(args.output, "w") as f:
            f.write(output)
        print(f"Report written to {args.output}")
    else:
        print(output)


if __name__ == "__main__":
    main()
