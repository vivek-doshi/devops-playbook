#!/usr/bin/env python3
"""
finops/scripts/reserved-capacity-advisor.py
Run this quarterly, after reviewing 3 months of stable usage data.
Do not run immediately after a major architecture change - usage patterns need time to stabilize.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


# <-- UPDATE QUARTERLY
AWS_DISCOUNT_TABLE = {"1yr": 0.35, "3yr": 0.55}
# <-- UPDATE QUARTERLY
AZURE_DISCOUNT_TABLE = {"1yr": 0.32, "3yr": 0.50}
# <-- UPDATE QUARTERLY
GCP_DISCOUNT_TABLE = {"1yr": 0.25, "3yr": 0.45}


@dataclass
class Candidate:
    namespace: str
    workload: str
    container: str
    cloud: str
    on_demand_monthly_usd: float
    variance_pct: float
    age_months: float


def run_json(cmd: list[str]) -> dict[str, Any]:
    out = subprocess.run(cmd, check=True, capture_output=True, text=True)
    return json.loads(out.stdout)


def load_base_analysis(cloud: str) -> dict[str, Any]:
    script_path = Path(__file__).with_name("analyze-reserved-capacity.py")
    cmd = [
        sys.executable,
        str(script_path),
        "--all-namespaces",
        "--cloud-provider",
        cloud,
        "--format",
        "json",
    ]
    out = subprocess.run(cmd, check=True, capture_output=True, text=True)
    return json.loads(out.stdout)


def fetch_workload_ages() -> dict[tuple[str, str], float]:
    ages: dict[tuple[str, str], float] = {}
    try:
        payload = run_json(["kubectl", "get", "deploy", "-A", "-o", "json"])
        now = datetime.now(timezone.utc)
        for item in payload.get("items", []):
            ns = item.get("metadata", {}).get("namespace", "default")
            name = item.get("metadata", {}).get("name", "unknown")
            created = item.get("metadata", {}).get("creationTimestamp")
            if not created:
                continue
            created_dt = datetime.fromisoformat(created.replace("Z", "+00:00"))
            age_months = max(0.0, (now - created_dt).days / 30.0)
            ages[(ns, name)] = age_months
    except Exception as exc:  # noqa: BLE001
        print(f"WARNING: could not fetch deployment ages ({exc}); defaulting to 6 months.", file=sys.stderr)
    return ages


def cloud_discount_table(cloud: str) -> dict[str, float]:
    if cloud == "azure":
        return AZURE_DISCOUNT_TABLE
    if cloud == "gcp":
        return GCP_DISCOUNT_TABLE
    return AWS_DISCOUNT_TABLE


def score_risk(age_months: float, variance_pct: float) -> str:
    if age_months < 3 or variance_pct > 30:
        return "high"
    if 3 <= age_months <= 6 or 10 <= variance_pct <= 30:
        return "medium"
    return "low"


def risk_rank(risk: str) -> int:
    order = {"low": 0, "medium": 1, "high": 2}
    return order[risk]


def build_recommendations(
    rows: list[Candidate],
    cloud: str,
    min_savings: float,
    max_risk: str,
    preferred_term: str,
) -> list[dict[str, Any]]:
    discounts = cloud_discount_table(cloud)
    max_allowed = risk_rank(max_risk)
    recommendations: list[dict[str, Any]] = []

    for row in rows:
        risk = score_risk(row.age_months, row.variance_pct)
        if risk_rank(risk) > max_allowed:
            continue

        # Enforced guardrail: never recommend 3-year commitment for workloads younger than 3 months.
        terms_to_consider = ["1yr", "3yr"]
        if row.age_months < 3:
            terms_to_consider = ["1yr"]

        comparisons: dict[str, dict[str, float]] = {}
        for term in terms_to_consider:
            discount = discounts.get(term, 0.0)
            committed_monthly = row.on_demand_monthly_usd * (1 - discount)
            monthly_savings = row.on_demand_monthly_usd - committed_monthly
            annual_savings = monthly_savings * 12
            upfront_delta = committed_monthly * 12
            break_even_months = (upfront_delta / monthly_savings) if monthly_savings > 0 else 999.0
            comparisons[term] = {
                "discount": discount,
                "committed_monthly_usd": round(committed_monthly, 2),
                "annual_savings_usd": round(annual_savings, 2),
                "break_even_months": round(break_even_months, 1),
            }

        selected_term = preferred_term if preferred_term in comparisons else "1yr"
        selected = comparisons[selected_term]
        if selected["annual_savings_usd"] < min_savings:
            continue

        recommendations.append(
            {
                "resource": f"{row.namespace}/{row.workload}",
                "cloud": row.cloud,
                "risk": risk,
                "age_months": round(row.age_months, 1),
                "variance_pct": round(row.variance_pct, 1),
                "recommended_term": selected_term,
                "on_demand_monthly_usd": round(row.on_demand_monthly_usd, 2),
                "committed_monthly_usd": selected["committed_monthly_usd"],
                "annual_savings_usd": selected["annual_savings_usd"],
                "break_even_months": selected["break_even_months"],
                "comparison": comparisons,
            }
        )

    recommendations.sort(key=lambda x: x["annual_savings_usd"], reverse=True)
    return recommendations


def markdown_proposal(recommendations: list[dict[str, Any]], cloud: str) -> str:
    total_annual = sum(r["annual_savings_usd"] for r in recommendations)
    lines = [
        "# Reserved Capacity Commitment Proposal",
        "",
        f"Generated: {datetime.now(timezone.utc).isoformat()}",
        f"Cloud: {cloud}",
        "",
        "## Recommended Commitments",
        "",
        "| Resource | Risk | Age (months) | Variance | Term | On-demand | Committed | Annual Savings | Break-even |",
        "|---|---|---:|---:|---|---:|---:|---:|---:|",
    ]
    for r in recommendations:
        lines.append(
            f"| {r['resource']} | {r['risk']} | {r['age_months']:.1f} | {r['variance_pct']:.1f}% | {r['recommended_term']} | "
            f"${r['on_demand_monthly_usd']:.2f}/mo | ${r['committed_monthly_usd']:.2f}/mo | ${r['annual_savings_usd']:.2f}/yr | {r['break_even_months']:.1f} months |"
        )

    lines.extend(["", "## 1-Year vs 3-Year Comparison", ""])
    for r in recommendations:
        cmp_1 = r["comparison"].get("1yr")
        cmp_3 = r["comparison"].get("3yr")
        lines.append(f"### {r['resource']}")
        if cmp_1:
            lines.append(
                f"- 1yr: committed ${cmp_1['committed_monthly_usd']:.2f}/mo, savings ${cmp_1['annual_savings_usd']:.2f}/yr, break-even {cmp_1['break_even_months']:.1f} months"
            )
        if cmp_3:
            lines.append(
                f"- 3yr: committed ${cmp_3['committed_monthly_usd']:.2f}/mo, savings ${cmp_3['annual_savings_usd']:.2f}/yr, break-even {cmp_3['break_even_months']:.1f} months"
            )
        if not cmp_3:
            lines.append("- 3yr: not recommended (workload younger than 3 months)")
        lines.append("")

    lines.extend(
        [
            "## Risk Assessment",
            "",
            "- low: workload has been running for >6 months with <10% resource variance",
            "- medium: workload is 3-6 months old or has 10-30% variance",
            "- high: workload is <3 months old or has >30% variance",
            "",
            f"## Total Annual Savings if Adopted: ${total_annual:.2f}",
            "",
            "## Execution Guidance",
            "",
            "1. Validate workloads are still stable in the last 90 days before commitment.",
            "2. Prefer 1-year commitments unless utilization variance is very low and long-term demand is proven.",
            "3. Submit this proposal for leadership review before purchase.",
            "4. Execute commitments via cloud console or Terraform module updates.",
        ]
    )
    return "\n".join(lines) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate reserved capacity commitment proposals with risk scoring")
    parser.add_argument("--min-savings", type=float, default=500.0, help="Minimum annual savings (USD) required")
    parser.add_argument("--max-risk", choices=["low", "medium", "high"], default="medium", help="Maximum allowed risk level")
    parser.add_argument("--term", choices=["1yr", "3yr"], default="1yr", help="Preferred commitment term")
    parser.add_argument("--cloud-provider", choices=["aws", "azure", "gcp"], default="aws", help="Cloud provider")
    parser.add_argument("--output-proposal", help="Write markdown proposal to this path")
    parser.add_argument("--output-json", help="Write machine-readable recommendations to this path")
    args = parser.parse_args()

    base = load_base_analysis(args.cloud_provider)
    ages = fetch_workload_ages()

    rows: list[Candidate] = []
    for item in base.get("stable_workloads", []):
        ns = item.get("namespace", "default")
        workload = item.get("workload", "unknown")
        age = ages.get((ns, workload), 6.0)
        rows.append(
            Candidate(
                namespace=ns,
                workload=workload,
                container=item.get("container", "unknown"),
                cloud=args.cloud_provider.upper(),
                on_demand_monthly_usd=float(item.get("on_demand_monthly_usd", 0.0)),
                variance_pct=float(item.get("cpu_variance_pct", 0.0)),
                age_months=age,
            )
        )

    recommendations = build_recommendations(
        rows,
        cloud=args.cloud_provider,
        min_savings=args.min_savings,
        max_risk=args.max_risk,
        preferred_term=args.term,
    )

    result = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "cloud": args.cloud_provider,
        "min_savings": args.min_savings,
        "max_risk": args.max_risk,
        "preferred_term": args.term,
        "recommendations": recommendations,
    }

    proposal = markdown_proposal(recommendations, args.cloud_provider)
    if args.output_proposal:
        Path(args.output_proposal).write_text(proposal, encoding="utf-8")
        print(f"Proposal written to {args.output_proposal}")
    else:
        print(proposal)

    if args.output_json:
        Path(args.output_json).write_text(json.dumps(result, indent=2), encoding="utf-8")
        print(f"Recommendation JSON written to {args.output_json}")

    cache_path = Path("finops/scripts/.last-reserved-advisor.json")
    cache_path.write_text(json.dumps(result, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
