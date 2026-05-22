"""
finops/scripts/test_analyze_rightsizing.py
Unit tests for analyze-rightsizing.py cost impact calculation functions.

Run: pytest finops/scripts/test_analyze_rightsizing.py -v
"""

import importlib.util
import sys
from pathlib import Path

# Load the module under test without executing __main__
_script = Path(__file__).parent / "analyze-rightsizing.py"
_spec = importlib.util.spec_from_file_location("analyze_rightsizing", _script)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)

parse_cpu = _mod.parse_cpu
parse_memory = _mod.parse_memory
calculate_monthly_cost = _mod.calculate_monthly_cost
classify_priority = _mod.classify_priority
build_report = _mod.build_report
fetch_pricing = _mod.fetch_pricing
DEFAULT_CPU_HOURLY_RATE_USD = _mod.DEFAULT_CPU_HOURLY_RATE_USD
DEFAULT_MEMORY_HOURLY_RATE_USD = _mod.DEFAULT_MEMORY_HOURLY_RATE_USD


# ─── parse_cpu ────────────────────────────────────────────────────────────────

class TestParseCpu:
    def test_cores(self):
        assert parse_cpu("2") == 2.0

    def test_millicore(self):
        assert parse_cpu("500m") == 0.5

    def test_millicore_1000(self):
        assert parse_cpu("1000m") == 1.0

    def test_none(self):
        assert parse_cpu(None) == 0.0

    def test_float_string(self):
        assert parse_cpu("1.5") == 1.5


# ─── parse_memory ─────────────────────────────────────────────────────────────

class TestParseMemory:
    def test_gi(self):
        assert parse_memory("1Gi") == 1.0

    def test_mi(self):
        result = parse_memory("512Mi")
        assert abs(result - 0.5) < 0.01

    def test_ki(self):
        result = parse_memory("1048576Ki")
        assert abs(result - 1.0) < 0.01

    def test_none(self):
        assert parse_memory(None) == 0.0

    def test_8gi(self):
        assert parse_memory("8Gi") == 8.0

    def test_4gi(self):
        assert parse_memory("4Gi") == 4.0


# ─── calculate_monthly_cost ───────────────────────────────────────────────────

class TestCalculateMonthlyCost:
    CPU_RATE = 0.048
    MEM_RATE = 0.006

    def test_zero(self):
        assert calculate_monthly_cost(0, 0, self.CPU_RATE, self.MEM_RATE) == 0.0

    def test_cpu_only(self):
        # 1 core * $0.048/hr * 730 = $35.04
        result = calculate_monthly_cost(1.0, 0, self.CPU_RATE, self.MEM_RATE)
        assert abs(result - 35.04) < 0.01

    def test_memory_only(self):
        # 1 GiB * $0.006/hr * 730 = $4.38
        result = calculate_monthly_cost(0, 1.0, self.CPU_RATE, self.MEM_RATE)
        assert abs(result - 4.38) < 0.01

    def test_combined(self):
        # 2 cores + 4 GiB = (2*0.048 + 4*0.006)*730 = (0.096+0.024)*730 = $87.60
        result = calculate_monthly_cost(2.0, 4.0, self.CPU_RATE, self.MEM_RATE)
        assert abs(result - 87.60) < 0.01

    def test_halving_resources_halves_cost(self):
        full = calculate_monthly_cost(2.0, 4.0, self.CPU_RATE, self.MEM_RATE)
        half = calculate_monthly_cost(1.0, 2.0, self.CPU_RATE, self.MEM_RATE)
        assert abs(full - half * 2) < 0.01


# ─── classify_priority ────────────────────────────────────────────────────────

class TestClassifyPriority:
    def test_high_at_20(self):
        assert classify_priority(20.0) == "high"

    def test_high_above_20(self):
        assert classify_priority(50.0) == "high"

    def test_medium_at_10(self):
        assert classify_priority(10.0) == "medium"

    def test_medium_at_19(self):
        assert classify_priority(19.9) == "medium"

    def test_low_below_10(self):
        assert classify_priority(5.0) == "low"

    def test_low_at_zero(self):
        assert classify_priority(0.0) == "low"

    def test_medium_at_15(self):
        assert classify_priority(15.0) == "medium"


# ─── build_report ─────────────────────────────────────────────────────────────

class TestBuildReport:
    PRICING = {
        "cpu_hourly_rate": DEFAULT_CPU_HOURLY_RATE_USD,
        "memory_hourly_rate": DEFAULT_MEMORY_HOURLY_RATE_USD,
    }
    MOCK_VPA = [
        {
            "metadata": {"name": "test-vpa", "namespace": "test-ns"},
            "spec": {"targetRef": {"name": "my-app", "kind": "Deployment"}},
            "status": {
                "recommendation": {
                    "containerRecommendations": [
                        {
                            "containerName": "app",
                            "target": {"cpu": "500m", "memory": "256Mi"},
                        }
                    ]
                }
            },
        }
    ]

    def test_report_structure(self):
        report = build_report(self.MOCK_VPA, self.PRICING, 20.0, "test-ns")
        assert "report_id" in report
        assert "summary" in report
        assert "recommendations" in report
        assert "generated_at" in report

    def test_summary_counts(self):
        report = build_report(self.MOCK_VPA, self.PRICING, 20.0, "test-ns")
        s = report["summary"]
        assert s["total_workloads"] == 1
        assert s["total_containers"] == 1

    def test_empty_vpas(self):
        report = build_report([], self.PRICING, 20.0, "test-ns")
        assert report["summary"]["total_containers"] == 0
        assert report["summary"]["total_potential_savings_usd"] == 0

    def test_recommendation_fields(self):
        report = build_report(self.MOCK_VPA, self.PRICING, 20.0, "test-ns")
        rec = report["recommendations"][0]
        assert "workload_name" in rec
        assert "potential_monthly_savings_usd" in rec
        assert "savings_percentage" in rec
        assert "priority" in rec
        assert "is_high_priority" in rec

    def test_savings_are_non_negative_for_downsizing(self):
        """When recommended < current, savings should be positive."""
        report = build_report(self.MOCK_VPA, self.PRICING, 20.0, "test-ns")
        # The mock uses 2x target as current, so savings should be positive
        for rec in report["recommendations"]:
            assert rec["potential_monthly_savings_usd"] >= 0

    def test_sorted_by_savings_descending(self):
        """Recommendations should be sorted by savings descending."""
        multi_vpa = self.MOCK_VPA + [
            {
                "metadata": {"name": "big-vpa", "namespace": "test-ns"},
                "spec": {"targetRef": {"name": "big-app", "kind": "Deployment"}},
                "status": {
                    "recommendation": {
                        "containerRecommendations": [
                            {
                                "containerName": "app",
                                "target": {"cpu": "100m", "memory": "64Mi"},
                            }
                        ]
                    }
                },
            }
        ]
        report = build_report(multi_vpa, self.PRICING, 20.0, "test-ns")
        savings = [r["potential_monthly_savings_usd"] for r in report["recommendations"]]
        assert savings == sorted(savings, reverse=True)


# ─── fetch_pricing fallback ───────────────────────────────────────────────────

class TestFetchPricingFallback:
    def test_returns_defaults_on_failure(self):
        pricing = fetch_pricing("http://localhost:9999/nonexistent")
        assert pricing["cpu_hourly_rate"] == DEFAULT_CPU_HOURLY_RATE_USD
        assert pricing["memory_hourly_rate"] == DEFAULT_MEMORY_HOURLY_RATE_USD

    def test_pricing_keys_present(self):
        pricing = fetch_pricing("http://localhost:9999/nonexistent")
        assert "cpu_hourly_rate" in pricing
        assert "memory_hourly_rate" in pricing
