"""
finops/scripts/test_detect_underutilized.py
Unit tests for detect-underutilized.py

Run: pytest finops/scripts/test_detect_underutilized.py -v
"""

import importlib.util
from pathlib import Path

_script = Path(__file__).parent / "detect-underutilized.py"
_spec = importlib.util.spec_from_file_location("detect_underutilized", _script)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)

build_report = _mod.build_report
DEFAULT_UTILIZATION_THRESHOLD = _mod.DEFAULT_UTILIZATION_THRESHOLD
DEFAULT_CPU_HOURLY_RATE = _mod.DEFAULT_CPU_HOURLY_RATE
DEFAULT_MEMORY_HOURLY_RATE = _mod.DEFAULT_MEMORY_HOURLY_RATE


def make_workload(
    pod="pod-1",
    namespace="ns",
    container="app",
    cpu_pct=50.0,
    mem_pct=60.0,
):
    return {
        "namespace": namespace,
        "pod": pod,
        "container": container,
        "cpu_utilization_pct": cpu_pct,
        "memory_utilization_pct": mem_pct,
    }


class TestThresholdDetection:
    def test_no_underutilized(self):
        workloads = [make_workload(cpu_pct=50.0, mem_pct=60.0)]
        report = build_report(workloads, DEFAULT_UTILIZATION_THRESHOLD)
        assert report["summary"]["underutilized_count"] == 0
        assert report["underutilized"] == []

    def test_cpu_underutilized(self):
        workloads = [make_workload(cpu_pct=5.0, mem_pct=60.0)]
        report = build_report(workloads, DEFAULT_UTILIZATION_THRESHOLD)
        assert report["summary"]["underutilized_count"] == 1
        assert report["underutilized"][0]["cpu_underutilized"] is True
        assert report["underutilized"][0]["memory_underutilized"] is False

    def test_memory_underutilized(self):
        workloads = [make_workload(cpu_pct=50.0, mem_pct=5.0)]
        report = build_report(workloads, DEFAULT_UTILIZATION_THRESHOLD)
        assert report["summary"]["underutilized_count"] == 1
        assert report["underutilized"][0]["cpu_underutilized"] is False
        assert report["underutilized"][0]["memory_underutilized"] is True

    def test_both_underutilized(self):
        workloads = [make_workload(cpu_pct=3.0, mem_pct=7.0)]
        report = build_report(workloads, DEFAULT_UTILIZATION_THRESHOLD)
        assert report["underutilized"][0]["cpu_underutilized"] is True
        assert report["underutilized"][0]["memory_underutilized"] is True

    def test_exactly_at_threshold_is_not_underutilized(self):
        threshold = 20.0
        workloads = [make_workload(cpu_pct=20.0, mem_pct=20.0)]
        report = build_report(workloads, threshold)
        assert report["summary"]["underutilized_count"] == 0

    def test_just_below_threshold_is_underutilized(self):
        threshold = 20.0
        workloads = [make_workload(cpu_pct=19.9, mem_pct=60.0)]
        report = build_report(workloads, threshold)
        assert report["summary"]["underutilized_count"] == 1

    def test_custom_threshold(self):
        workloads = [make_workload(cpu_pct=35.0, mem_pct=80.0)]
        # At default 20% threshold → NOT underutilized
        assert build_report(workloads, 20.0)["summary"]["underutilized_count"] == 0
        # At 40% threshold → IS underutilized
        assert build_report(workloads, 40.0)["summary"]["underutilized_count"] == 1


class TestCostCalculation:
    def test_cpu_waste_estimate_positive(self):
        workloads = [make_workload(cpu_pct=5.0, mem_pct=60.0)]
        report = build_report(workloads, DEFAULT_UTILIZATION_THRESHOLD)
        waste = report["underutilized"][0]["estimated_monthly_waste_usd"]
        assert waste > 0

    def test_memory_waste_estimate_positive(self):
        workloads = [make_workload(cpu_pct=50.0, mem_pct=5.0)]
        report = build_report(workloads, DEFAULT_UTILIZATION_THRESHOLD)
        waste = report["underutilized"][0]["estimated_monthly_waste_usd"]
        assert waste > 0

    def test_higher_underutilization_higher_waste(self):
        w_low = [make_workload(cpu_pct=15.0, mem_pct=60.0)]
        w_high = [make_workload(cpu_pct=1.0, mem_pct=60.0)]
        waste_low = build_report(w_low, 20.0)["underutilized"][0]["estimated_monthly_waste_usd"]
        waste_high = build_report(w_high, 20.0)["underutilized"][0]["estimated_monthly_waste_usd"]
        assert waste_high > waste_low

    def test_total_waste_sums_correctly(self):
        workloads = [
            make_workload("p1", cpu_pct=5.0, mem_pct=5.0),
            make_workload("p2", cpu_pct=3.0, mem_pct=7.0),
        ]
        report = build_report(workloads, DEFAULT_UTILIZATION_THRESHOLD)
        total = report["summary"]["estimated_monthly_waste_usd"]
        item_sum = sum(w["estimated_monthly_waste_usd"] for w in report["underutilized"])
        assert abs(total - item_sum) < 0.01

    def test_waste_is_zero_for_compliant_workloads(self):
        workloads = [make_workload(cpu_pct=80.0, mem_pct=90.0)]
        report = build_report(workloads, DEFAULT_UTILIZATION_THRESHOLD)
        assert report["summary"]["estimated_monthly_waste_usd"] == 0.0


class TestReportStructure:
    def test_empty_workloads(self):
        report = build_report([], DEFAULT_UTILIZATION_THRESHOLD)
        assert report["summary"]["total_workloads"] == 0
        assert report["summary"]["underutilized_count"] == 0
        assert report["underutilized"] == []

    def test_sorted_by_waste_descending(self):
        workloads = [
            make_workload("p1", cpu_pct=18.0, mem_pct=60.0),
            make_workload("p2", cpu_pct=1.0, mem_pct=1.0),
        ]
        report = build_report(workloads, DEFAULT_UTILIZATION_THRESHOLD)
        wastes = [w["estimated_monthly_waste_usd"] for w in report["underutilized"]]
        assert wastes == sorted(wastes, reverse=True)

    def test_priority_high_for_large_waste(self):
        # A workload with very low utilization should get "high" or "medium" priority
        workloads = [make_workload(cpu_pct=1.0, mem_pct=1.0)]
        report = build_report(workloads, DEFAULT_UTILIZATION_THRESHOLD)
        assert report["underutilized"][0]["priority"] in ("high", "medium", "low")

    def test_removal_recommendation_for_near_zero_utilization(self):
        workloads = [make_workload(cpu_pct=2.0, mem_pct=3.0)]
        report = build_report(workloads, DEFAULT_UTILIZATION_THRESHOLD)
        action = report["underutilized"][0]["recommended_action"]
        assert "remov" in action.lower() or "Reduce" in action

    def test_report_has_required_keys(self):
        report = build_report(
            [make_workload(cpu_pct=5.0, mem_pct=5.0)], DEFAULT_UTILIZATION_THRESHOLD
        )
        assert "report_id" in report
        assert "generated_at" in report
        assert "threshold_pct" in report
        assert "lookback_days" in report
        assert "summary" in report
        assert "underutilized" in report

    def test_multiple_namespaces(self):
        workloads = [
            make_workload("p1", namespace="ns-a", cpu_pct=5.0, mem_pct=5.0),
            make_workload("p2", namespace="ns-b", cpu_pct=5.0, mem_pct=5.0),
        ]
        report = build_report(workloads, DEFAULT_UTILIZATION_THRESHOLD)
        namespaces = {w["namespace"] for w in report["underutilized"]}
        assert "ns-a" in namespaces
        assert "ns-b" in namespaces
