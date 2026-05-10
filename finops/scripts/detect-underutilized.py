#!/usr/bin/env python3
"""
finops/scripts/detect-underutilized.py
Identify workloads with CPU or memory utilization below 20% over 7 days
and generate a cost optimization report.

Usage:
  python detect-underutilized.py --namespace team-a
  python detect-underutilized.py --all-namespaces --threshold 20
  python detect-underutilized.py --all-namespaces --format json --output report.json

Requirements:
  pip install requests
"""

import argparse
import json
import sys
from datetime import datetime, timezone
from typing import Any

DEFAULT_UTILIZATION_THRESHOLD = 20.0  # percent
DEFAULT_CPU_HOURLY_RATE = 0.048       # $/vCPU-hour
DEFAULT_MEMORY_HOURLY_RATE = 0.006    # $/GiB-hour


def fetch_utilization(prometheus_url: str, namespace: str | None, lookback: str = "7d") -> list[dict[str, Any]]:
    """
    Query Prometheus for CPU and memory utilization per workload.
    Returns list of workload utilization dicts.
    """
    try:
        import requests  # noqa: PLC0415

        ns_filter = f',namespace="{namespace}"' if namespace else ""

        # CPU utilization: avg over lookback period
        cpu_query = (
            f'avg by (namespace, pod, container) ('
            f'  rate(container_cpu_usage_seconds_total{{container!=""{ns_filter}}}[{lookback}])'
            f') / avg by (namespace, pod, container) ('
            f'  kube_pod_container_resource_requests{{resource="cpu",container!=""{ns_filter}}}'
            f') * 100'
        )
        # Memory utilization
        mem_query = (
            f'avg by (namespace, pod, container) ('
            f'  container_memory_working_set_bytes{{container!=""{ns_filter}}}'
            f') / avg by (namespace, pod, container) ('
            f'  kube_pod_container_resource_requests{{resource="memory",container!=""{ns_filter}}}'
            f') * 100'
        )

        def run_query(q):
            resp = requests.get(
                f"{prometheus_url}/api/v1/query",
                params={"query": q},
                timeout=30,
            )
            resp.raise_for_status()
            return resp.json().get("data", {}).get("result", [])

        cpu_results = run_query(cpu_query)
        mem_results = run_query(mem_query)

        # Merge by (namespace, pod, container)
        data: dict[tuple, dict] = {}
        for r in cpu_results:
            key = (r["metric"].get("namespace"), r["metric"].get("pod"), r["metric"].get("container"))
            data[key] = {"cpu_utilization_pct": float(r["value"][1])}
        for r in mem_results:
            key = (r["metric"].get("namespace"), r["metric"].get("pod"), r["metric"].get("container"))
            data.setdefault(key, {})["memory_utilization_pct"] = float(r["value"][1])

        return [
            {
                "namespace": k[0],
                "pod": k[1],
                "container": k[2],
                "cpu_utilization_pct": v.get("cpu_utilization_pct", 0),
                "memory_utilization_pct": v.get("memory_utilization_pct", 0),
            }
            for k, v in data.items()
        ]
    except Exception as exc:  # noqa: BLE001
        print(f"WARNING: Prometheus unavailable ({exc}). Using mock data.", file=sys.stderr)
        return _mock_utilization(namespace)


def _mock_utilization(namespace: str | None) -> list[dict[str, Any]]:
    ns = namespace or "team-a"
    return [
        {"namespace": ns, "pod": "api-pod-1", "container": "app",
         "cpu_utilization_pct": 8.5, "memory_utilization_pct": 12.0},
        {"namespace": ns, "pod": "worker-pod-1", "container": "worker",
         "cpu_utilization_pct": 45.0, "memory_utilization_pct": 60.0},
        {"namespace": ns, "pod": "cache-pod-1", "container": "redis",
         "cpu_utilization_pct": 5.0, "memory_utilization_pct": 80.0},
        {"namespace": ns, "pod": "batch-pod-1", "container": "batch",
         "cpu_utilization_pct": 3.0, "memory_utilization_pct": 7.0},
    ]


def build_report(workloads: list[dict[str, Any]], threshold: float) -> dict[str, Any]:
    """Identify underutilized workloads and estimate waste."""
    underutilized = []
    for w in workloads:
        cpu_pct = w.get("cpu_utilization_pct", 100)
        mem_pct = w.get("memory_utilization_pct", 100)
        is_cpu_under = cpu_pct < threshold
        is_mem_under = mem_pct < threshold

        if not (is_cpu_under or is_mem_under):
            continue

        # Estimate wasted cost (assuming utilization-proportional waste)
        cpu_waste_fraction = max(0, (threshold - cpu_pct) / 100) if is_cpu_under else 0
        mem_waste_fraction = max(0, (threshold - mem_pct) / 100) if is_mem_under else 0
        monthly_waste = (
            cpu_waste_fraction * DEFAULT_CPU_HOURLY_RATE * 730 +
            mem_waste_fraction * DEFAULT_MEMORY_HOURLY_RATE * 730
        )

        recommended_action = []
        if is_cpu_under:
            recommended_action.append(f"Reduce CPU request by ~{threshold - cpu_pct:.0f}%")
        if is_mem_under:
            recommended_action.append(f"Reduce memory request by ~{threshold - mem_pct:.0f}%")
        if cpu_pct < 5 and mem_pct < 5:
            recommended_action.append("Consider removing this workload entirely")

        underutilized.append({
            **w,
            "cpu_underutilized": is_cpu_under,
            "memory_underutilized": is_mem_under,
            "estimated_monthly_waste_usd": round(monthly_waste, 2),
            "recommended_action": "; ".join(recommended_action),
            "priority": "high" if monthly_waste > 50 else "medium" if monthly_waste > 20 else "low",
        })

    underutilized.sort(key=lambda x: x["estimated_monthly_waste_usd"], reverse=True)
    total_waste = sum(w["estimated_monthly_waste_usd"] for w in underutilized)

    return {
        "report_id": f"underutilized-{datetime.now(timezone.utc).strftime('%Y-%m-%d')}",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "threshold_pct": threshold,
        "lookback_days": 7,
        "summary": {
            "total_workloads": len(workloads),
            "underutilized_count": len(underutilized),
            "estimated_monthly_waste_usd": round(total_waste, 2),
        },
        "underutilized": underutilized,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Detect underutilized workloads")
    parser.add_argument("--namespace", "-n")
    parser.add_argument("--all-namespaces", "-A", action="store_true")
    parser.add_argument("--prometheus-url", default="http://prometheus-operated.monitoring.svc.cluster.local:9090")
    parser.add_argument("--threshold", type=float, default=DEFAULT_UTILIZATION_THRESHOLD)
    parser.add_argument("--format", choices=["text", "json"], default="text")
    parser.add_argument("--output", "-o")
    args = parser.parse_args()

    ns = None if args.all_namespaces else args.namespace
    workloads = fetch_utilization(args.prometheus_url, ns)
    report = build_report(workloads, args.threshold)

    output = json.dumps(report, indent=2) if args.format == "json" else _text(report)

    if args.output:
        with open(args.output, "w") as f:
            f.write(output)
        print(f"Report written to {args.output}")
    else:
        print(output)

    if report["summary"]["underutilized_count"] > 0:
        sys.exit(2)


def _text(report: dict[str, Any]) -> str:
    s = report["summary"]
    lines = [
        "=" * 60,
        "  FinOps Underutilized Workload Report",
        f"  Threshold: {report['threshold_pct']}% | Lookback: {report['lookback_days']}d",
        "=" * 60,
        f"  Total workloads    : {s['total_workloads']}",
        f"  Underutilized      : {s['underutilized_count']}",
        f"  Estimated waste    : ${s['estimated_monthly_waste_usd']:.2f}/month",
        "=" * 60,
    ]
    for w in report["underutilized"][:20]:
        lines.append(f"\n  {w['pod']}/{w['container']} ({w['namespace']})")
        lines.append(f"    CPU util: {w['cpu_utilization_pct']:.1f}%  MEM util: {w['memory_utilization_pct']:.1f}%")
        lines.append(f"    Waste   : ${w['estimated_monthly_waste_usd']:.2f}/month")
        lines.append(f"    Action  : {w['recommended_action']}")
    return "\n".join(lines)


if __name__ == "__main__":
    main()
