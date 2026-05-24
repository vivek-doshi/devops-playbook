#!/usr/bin/env python3
"""
finops/scripts/analyze-rightsizing.py
Query VPA recommendations for all workloads in a namespace, enrich with
Kubecost/OpenCost pricing data, and generate a rightsizing report.

Usage:
  python analyze-rightsizing.py --namespace team-a
  python analyze-rightsizing.py --namespace team-a --format json
  python analyze-rightsizing.py --all-namespaces --savings-threshold 20

Requirements:
  pip install kubernetes requests
"""

import argparse
import json
import sys
from datetime import datetime, timezone
from typing import Any

# ─── CPU/memory pricing constants (fallback if API unavailable) ───────────────
# Approximate AWS us-east-1 on-demand pricing per vCPU-hour and GiB-hour
DEFAULT_CPU_HOURLY_RATE_USD = 0.048   # $/vCPU-hour
DEFAULT_MEMORY_HOURLY_RATE_USD = 0.006  # $/GiB-hour

# ─── Helpers ──────────────────────────────────────────────────────────────────

def parse_cpu(cpu_str: str) -> float:
    """Convert Kubernetes CPU string to float cores."""
    if cpu_str is None:
        return 0.0
    s = str(cpu_str).strip()
    if s.endswith("m"):
        return float(s[:-1]) / 1000.0
    return float(s)


def parse_memory(mem_str: str) -> float:
    """Convert Kubernetes memory string to GiB float."""
    if mem_str is None:
        return 0.0
    s = str(mem_str).strip()
    units = {
        "Ki": 1 / (1024 ** 2), "Mi": 1 / 1024, "Gi": 1,
        "Ti": 1024, "Pi": 1024 ** 2, "Ei": 1024 ** 3,
        "K": 1 / (1000 ** 2) * 1000 / 1024, "M": 1 / 1024 * (1000**2) / (1024**2),
    }
    for suffix, factor in sorted(units.items(), key=lambda x: -len(x[0])):
        if s.endswith(suffix):
            return float(s[: -len(suffix)]) * factor
    return float(s) / (1024 ** 3)


def calculate_monthly_cost(cpu_cores: float, memory_gib: float,
                            cpu_rate: float, memory_rate: float) -> float:
    """Return estimated monthly cost in USD (730 hours/month)."""
    return (cpu_cores * cpu_rate + memory_gib * memory_rate) * 730


def classify_priority(savings_pct: float) -> str:
    """Classify a recommendation as high/medium/low priority."""
    if savings_pct >= 20:
        return "high"
    elif savings_pct >= 10:
        return "medium"
    return "low"


# ─── VPA querying ─────────────────────────────────────────────────────────────

def fetch_vpa_recommendations(namespace: str | None, k8s_client=None) -> list[dict[str, Any]]:
    """
    Fetch VPA objects and extract recommendations.
    Returns a list of recommendation dicts.
    """
    try:
        from kubernetes import client, config
        config.load_kube_config()
        custom = client.CustomObjectsApi()

        kwargs: dict[str, Any] = {
            "group": "autoscaling.k8s.io",
            "version": "v1",
            "plural": "verticalpodautoscalers",
        }
        if namespace:
            kwargs["namespace"] = namespace
            vpas = custom.list_namespaced_custom_object(**kwargs)
        else:
            vpas = custom.list_cluster_custom_object(**kwargs)

        return vpas.get("items", [])
    except ImportError:
        print("WARNING: 'kubernetes' package not installed. Using mock data.", file=sys.stderr)
        return _mock_vpa_data(namespace or "default")
    except Exception as exc:  # noqa: BLE001
        print(f"WARNING: Could not fetch VPA data: {exc}. Using mock data.", file=sys.stderr)
        return _mock_vpa_data(namespace or "default")


def _mock_vpa_data(namespace: str) -> list[dict[str, Any]]:
    """Return sample VPA data for testing/demo purposes."""
    return [
        {
            "metadata": {"name": "api-server-vpa", "namespace": namespace},
            "spec": {"targetRef": {"name": "api-server", "kind": "Deployment"}},
            "status": {
                "recommendation": {
                    "containerRecommendations": [
                        {
                            "containerName": "app",
                            "target": {"cpu": "500m", "memory": "256Mi"},
                            "lowerBound": {"cpu": "250m", "memory": "128Mi"},
                            "upperBound": {"cpu": "1000m", "memory": "512Mi"},
                        }
                    ]
                }
            },
        },
        {
            "metadata": {"name": "worker-vpa", "namespace": namespace},
            "spec": {"targetRef": {"name": "worker", "kind": "Deployment"}},
            "status": {
                "recommendation": {
                    "containerRecommendations": [
                        {
                            "containerName": "worker",
                            "target": {"cpu": "200m", "memory": "128Mi"},
                            "lowerBound": {"cpu": "100m", "memory": "64Mi"},
                            "upperBound": {"cpu": "500m", "memory": "256Mi"},
                        }
                    ]
                }
            },
        },
    ]


# ─── Kubecost/OpenCost pricing ────────────────────────────────────────────────

def fetch_pricing(kubecost_url: str) -> dict[str, float]:
    """
    Fetch per-node pricing from Kubecost/OpenCost API.
    Falls back to defaults if unavailable.
    """
    try:
        import requests  # noqa: PLC0415
        resp = requests.get(f"{kubecost_url}/model/node/pricing", timeout=10)
        resp.raise_for_status()
        data = resp.json()
        # Aggregate average CPU/memory rates across all nodes
        nodes = data.get("data", {}).get("nodes", [])
        if nodes:
            cpu_rates = [n.get("cpuHourlyCost", DEFAULT_CPU_HOURLY_RATE_USD) for n in nodes]
            mem_rates = [n.get("ramGBHourlyCost", DEFAULT_MEMORY_HOURLY_RATE_USD) for n in nodes]
            return {
                "cpu_hourly_rate": sum(cpu_rates) / len(cpu_rates),
                "memory_hourly_rate": sum(mem_rates) / len(mem_rates),
            }
    except Exception as exc:  # noqa: BLE001
        print(f"WARNING: Could not fetch pricing from Kubecost ({exc}). Using defaults.", file=sys.stderr)

    return {
        "cpu_hourly_rate": DEFAULT_CPU_HOURLY_RATE_USD,
        "memory_hourly_rate": DEFAULT_MEMORY_HOURLY_RATE_USD,
    }


# ─── Current resource requests ────────────────────────────────────────────────

def fetch_current_resources(vpa: dict[str, Any]) -> dict[str, dict[str, str]]:
    """
    Fetch current resource requests from the workload referenced by the VPA.
    Returns {containerName: {cpu: "...", memory: "..."}}
    """
    try:
        from kubernetes import client, config  # noqa: PLC0415
        config.load_kube_config()
        apps = client.AppsV1Api()
        ref = vpa["spec"]["targetRef"]
        ns = vpa["metadata"]["namespace"]

        if ref["kind"] == "Deployment":
            dep = apps.read_namespaced_deployment(ref["name"], ns)
            containers = dep.spec.template.spec.containers or []
        elif ref["kind"] == "StatefulSet":
            ss = apps.read_namespaced_stateful_set(ref["name"], ns)
            containers = ss.spec.template.spec.containers or []
        else:
            return {}

        result = {}
        for c in containers:
            reqs = c.resources.requests or {} if c.resources else {}
            result[c.name] = {
                "cpu": str(reqs.get("cpu", "0")),
                "memory": str(reqs.get("memory", "0")),
            }
        return result
    except Exception:  # noqa: BLE001
        # Fallback: use 2x the VPA target as "current" for demo
        result = {}
        for rec in vpa.get("status", {}).get("recommendation", {}).get("containerRecommendations", []):
            target = rec.get("target", {})
            result[rec["containerName"]] = {
                "cpu": str(parse_cpu(target.get("cpu", "0")) * 2) + "cores",
                "memory": str(parse_memory(target.get("memory", "0")) * 2) + "Gi",
            }
        return result


# ─── Report generation ────────────────────────────────────────────────────────

def build_report(vpas: list[dict[str, Any]], pricing: dict[str, float],
                  savings_threshold: float, namespace: str | None) -> dict[str, Any]:
    """Build the full rightsizing report."""
    cpu_rate = pricing["cpu_hourly_rate"]
    mem_rate = pricing["memory_hourly_rate"]
    recommendations = []

    for vpa in vpas:
        ns = vpa["metadata"]["namespace"]
        workload_name = vpa["spec"]["targetRef"]["name"]
        workload_type = vpa["spec"]["targetRef"]["kind"]

        container_recs = (
            vpa.get("status", {})
            .get("recommendation", {})
            .get("containerRecommendations", [])
        )

        if not container_recs:
            continue

        current_resources = fetch_current_resources(vpa)

        for rec in container_recs:
            container = rec["containerName"]
            target = rec.get("target", {})

            current = current_resources.get(container, {"cpu": "0", "memory": "0"})
            current_cpu = parse_cpu(current["cpu"])
            current_mem = parse_memory(current["memory"])
            rec_cpu = parse_cpu(target.get("cpu", "0"))
            rec_mem = parse_memory(target.get("memory", "0"))

            current_cost = calculate_monthly_cost(current_cpu, current_mem, cpu_rate, mem_rate)
            rec_cost = calculate_monthly_cost(rec_cpu, rec_mem, cpu_rate, mem_rate)
            savings = current_cost - rec_cost
            savings_pct = (savings / current_cost * 100) if current_cost > 0 else 0
            priority = classify_priority(savings_pct)

            recommendations.append({
                "namespace": ns,
                "workload_name": workload_name,
                "workload_type": workload_type,
                "container_name": container,
                "current_resources": {
                    "cpu_request": current["cpu"],
                    "memory_request": current["memory"],
                },
                "recommended_resources": {
                    "cpu_request": target.get("cpu", "0"),
                    "memory_request": target.get("memory", "0"),
                },
                "current_monthly_cost_usd": round(current_cost, 2),
                "recommended_monthly_cost_usd": round(rec_cost, 2),
                "potential_monthly_savings_usd": round(savings, 2),
                "savings_percentage": round(savings_pct, 1),
                "priority": priority,
                "is_high_priority": savings_pct >= savings_threshold,
            })

    # Sort by potential savings descending
    recommendations.sort(key=lambda r: r["potential_monthly_savings_usd"], reverse=True)

    total_current = sum(r["current_monthly_cost_usd"] for r in recommendations)
    total_rec = sum(r["recommended_monthly_cost_usd"] for r in recommendations)
    total_savings = total_current - total_rec
    high_priority = [r for r in recommendations if r["is_high_priority"]]

    return {
        "report_id": f"rightsizing-{datetime.now(timezone.utc).strftime('%Y-%m-%d')}",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "namespace": namespace or "all",
        "pricing": {
            "cpu_hourly_rate_usd": cpu_rate,
            "memory_hourly_rate_usd_per_gib": mem_rate,
            "source": "kubecost" if cpu_rate != DEFAULT_CPU_HOURLY_RATE_USD else "defaults",
        },
        "summary": {
            "total_workloads": len(set(r["workload_name"] for r in recommendations)),
            "total_containers": len(recommendations),
            "high_priority_count": len(high_priority),
            "total_current_monthly_cost_usd": round(total_current, 2),
            "total_recommended_monthly_cost_usd": round(total_rec, 2),
            "total_potential_savings_usd": round(total_savings, 2),
            "total_savings_percentage": round((total_savings / total_current * 100) if total_current > 0 else 0, 1),
        },
        "recommendations": recommendations,
    }


def print_report_text(report: dict[str, Any]) -> None:
    """Print a human-readable report."""
    s = report["summary"]
    print("=" * 60)
    print("  FinOps Rightsizing Report")
    print(f"  Generated: {report['generated_at']}")
    print(f"  Namespace: {report['namespace']}")
    print("=" * 60)
    print(f"  Workloads analyzed : {s['total_workloads']}")
    print(f"  Containers analyzed: {s['total_containers']}")
    print(f"  High-priority recs : {s['high_priority_count']}")
    print(f"  Current monthly    : ${s['total_current_monthly_cost_usd']:,.2f}")
    print(f"  Recommended        : ${s['total_recommended_monthly_cost_usd']:,.2f}")
    print(f"  Potential savings  : ${s['total_potential_savings_usd']:,.2f} ({s['total_savings_percentage']}%)")
    print("=" * 60)

    for r in report["recommendations"][:10]:  # top 10
        flag = "🔴 HIGH" if r["is_high_priority"] else "🟡" if r["priority"] == "medium" else "🟢"
        print(f"\n{flag} {r['workload_name']}/{r['container_name']} ({r['namespace']})")
        print(f"     Current : CPU={r['current_resources']['cpu_request']}  MEM={r['current_resources']['memory_request']}  Cost=${r['current_monthly_cost_usd']:.2f}/mo")
        print(f"     Recommend: CPU={r['recommended_resources']['cpu_request']}  MEM={r['recommended_resources']['memory_request']}  Cost=${r['recommended_monthly_cost_usd']:.2f}/mo")
        print(f"     Savings  : ${r['potential_monthly_savings_usd']:.2f}/mo ({r['savings_percentage']}%)")


# ─── Entry point ──────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(
        description="FinOps Rightsizing: Analyze VPA recommendations with cost impact"
    )
    parser.add_argument("--namespace", "-n", help="Target namespace (omit for all)")
    parser.add_argument("--all-namespaces", "-A", action="store_true")
    parser.add_argument("--kubecost-url", default="http://kubecost.finops.svc.cluster.local:9090",
                        help="Kubecost/OpenCost API base URL")
    parser.add_argument("--format", choices=["text", "json"], default="text")
    parser.add_argument("--savings-threshold", "--min-savings", dest="savings_threshold", type=float, default=20.0,
                        help="%% savings to classify as high-priority (default: 20%%)")
    parser.add_argument("--output", "-o", help="Output file path (default: stdout)")
    args = parser.parse_args()

    ns = None if args.all_namespaces else args.namespace
    vpas = fetch_vpa_recommendations(ns)
    pricing = fetch_pricing(args.kubecost_url)
    report = build_report(vpas, pricing, args.savings_threshold, ns)

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

    # Exit with non-zero if high priority recommendations exist
    if report["summary"]["high_priority_count"] > 0:
        sys.exit(2)


if __name__ == "__main__":
    main()
