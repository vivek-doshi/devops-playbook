"""
finops/scripts/test_analyze_reserved_capacity.py
Unit tests for analyze-reserved-capacity.py

Run: pytest finops/scripts/test_analyze_reserved_capacity.py -v
"""

import importlib.util
from pathlib import Path

_script = Path(__file__).parent / "analyze-reserved-capacity.py"
_spec = importlib.util.spec_from_file_location("analyze_reserved_capacity", _script)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)

compute_variance_pct = _mod.compute_variance_pct
build_report = _mod.build_report
STABILITY_VARIANCE_THRESHOLD = _mod.STABILITY_VARIANCE_THRESHOLD
RESERVED_DISCOUNT = _mod.RESERVED_DISCOUNT


def make_workload(
    pod="api",
    namespace="ns",
    container="app",
    cpu_avg=1.0,
    cpu_p95=1.1,
    cpu_p5=0.9,
    mem_avg_gib=2.0,
):
    return {
        "namespace": namespace,
        "pod": pod,
        "container": container,
        "cpu_avg_cores": cpu_avg,
        "cpu_p95_cores": cpu_p95,
        "cpu_p5_cores": cpu_p5,
        "mem_avg_gib": mem_avg_gib,
    }


class TestVarianceCalculation:
    def test_stable_workload_low_variance(self):
        # p95 and p5 very close to avg → near-zero variance
        pct = compute_variance_pct(avg=1.0, p95=1.05, p5=0.95)
        assert pct < STABILITY_VARIANCE_THRESHOLD

    def test_volatile_workload_high_variance(self):
        pct = compute_variance_pct(avg=1.0, p95=5.0, p5=0.1)
        assert pct > STABILITY_VARIANCE_THRESHOLD

    def test_zero_avg_returns_zero(self):
        pct = compute_variance_pct(avg=0.0, p95=0.0, p5=0.0)
        assert pct == 0.0

    def test_variance_proportional_to_spread(self):
        narrow = compute_variance_pct(avg=1.0, p95=1.1, p5=0.9)
        wide = compute_variance_pct(avg=1.0, p95=2.0, p5=0.2)
        assert wide > narrow

    def test_exactly_at_threshold(self):
        # variance = (p95 - p5) / avg * 100 == 10  →  p95-p5 = 0.1 for avg=1
        pct = compute_variance_pct(avg=1.0, p95=1.05, p5=0.95)
        # 0.1 / 1.0 * 100 = 10.0
        assert abs(pct - 10.0) < 0.001


class TestStableWorkloadIdentification:
    def test_stable_workload_included(self):
        workloads = [make_workload(cpu_avg=1.0, cpu_p95=1.05, cpu_p5=0.95)]
        report = build_report(workloads, "aws")
        assert report["summary"]["stable_workloads"] == 1

    def test_volatile_workload_excluded(self):
        workloads = [make_workload(cpu_avg=1.0, cpu_p95=5.0, cpu_p5=0.1)]
        report = build_report(workloads, "aws")
        assert report["summary"]["stable_workloads"] == 0

    def test_mixed_workloads(self):
        workloads = [
            make_workload("stable", cpu_avg=1.0, cpu_p95=1.05, cpu_p5=0.95),
            make_workload("volatile", cpu_avg=1.0, cpu_p95=5.0, cpu_p5=0.1),
        ]
        report = build_report(workloads, "aws")
        assert report["summary"]["stable_workloads"] == 1
        assert report["summary"]["total_workloads_analyzed"] == 2

    def test_empty_workloads(self):
        report = build_report([], "aws")
        assert report["summary"]["stable_workloads"] == 0
        assert report["summary"]["total_potential_annual_savings_usd"] == 0.0


class TestSavingsCalculation:
    def test_savings_positive_for_stable_workload(self):
        workloads = [make_workload(cpu_avg=2.0, cpu_p95=2.1, cpu_p5=1.9, mem_avg_gib=4.0)]
        report = build_report(workloads, "aws")
        assert report["summary"]["total_potential_annual_savings_usd"] > 0

    def test_savings_scale_with_resource_size(self):
        small = [make_workload(cpu_avg=0.5, cpu_p95=0.52, cpu_p5=0.48, mem_avg_gib=1.0)]
        large = [make_workload(cpu_avg=4.0, cpu_p95=4.1, cpu_p5=3.9, mem_avg_gib=8.0)]
        savings_small = build_report(small, "aws")["summary"]["total_potential_annual_savings_usd"]
        savings_large = build_report(large, "aws")["summary"]["total_potential_annual_savings_usd"]
        assert savings_large > savings_small

    def test_higher_discount_provider_higher_savings(self):
        workloads = [make_workload(cpu_avg=2.0, cpu_p95=2.1, cpu_p5=1.9)]
        # GCP 1yr = 25%, AWS 1yr no-upfront = 30%
        savings_gcp = build_report(workloads, "gcp")["summary"]["total_potential_annual_savings_usd"]
        savings_aws = build_report(workloads, "aws")["summary"]["total_potential_annual_savings_usd"]
        assert savings_aws >= savings_gcp

    def test_annual_savings_equals_monthly_times_12(self):
        workloads = [make_workload(cpu_avg=1.0, cpu_p95=1.05, cpu_p5=0.95)]
        report = build_report(workloads, "aws")
        if report["stable_workloads"]:
            w = report["stable_workloads"][0]
            expected_annual = w["monthly_savings_usd"] * 12
            assert abs(w["annual_savings_usd"] - expected_annual) < 0.01

    def test_sorted_by_annual_savings_descending(self):
        workloads = [
            make_workload("small", cpu_avg=0.5, cpu_p95=0.52, cpu_p5=0.48),
            make_workload("large", cpu_avg=4.0, cpu_p95=4.1, cpu_p5=3.9),
        ]
        report = build_report(workloads, "aws")
        savings = [w["annual_savings_usd"] for w in report["stable_workloads"]]
        assert savings == sorted(savings, reverse=True)


class TestCloudProviders:
    def test_all_providers_accepted(self):
        workloads = [make_workload(cpu_avg=1.0, cpu_p95=1.05, cpu_p5=0.95)]
        for provider in ["aws", "azure", "gcp"]:
            report = build_report(workloads, provider)
            assert report["cloud_provider"] == provider

    def test_invalid_provider_falls_back_to_aws(self):
        workloads = [make_workload(cpu_avg=1.0, cpu_p95=1.05, cpu_p5=0.95)]
        # RESERVED_DISCOUNT.get() falls back to aws
        report = build_report(workloads, "unknown-cloud")
        assert report["summary"]["stable_workloads"] == 1

    def test_report_metadata(self):
        report = build_report([], "aws")
        assert "report_id" in report
        assert "generated_at" in report
        assert "analysis_period_days" in report
        assert "stability_threshold_pct" in report
        assert "available_terms" in report
