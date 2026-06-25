"""
finops/scripts/test_generate_cost_report.py
Unit tests for generate-cost-report.py

Run: pytest finops/scripts/test_generate_cost_report.py -v
"""

import importlib.util
import json
from pathlib import Path

_script = Path(__file__).parent / "generate-cost-report.py"
_spec = importlib.util.spec_from_file_location("generate_cost_report", _script)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)

build_report = _mod.build_report
report_to_csv = _mod.report_to_csv
month_to_range = _mod.month_to_range
SHARED_COSTS_DEFAULT = _mod.SHARED_COSTS_DEFAULT

SAMPLE_NS_COSTS = [
    {
        "name": "team-a",
        "properties": {"namespace": "team-a", "labels": {"finops.org/costcenter": "engineering"}},
        "cpuCost": 1000.0, "ramCost": 500.0, "pvCost": 200.0, "networkCost": 100.0,
        "totalCost": 1800.0,
    },
    {
        "name": "team-b",
        "properties": {"namespace": "team-b", "labels": {"finops.org/costcenter": "engineering"}},
        "cpuCost": 500.0, "ramCost": 200.0, "pvCost": 100.0, "networkCost": 50.0,
        "totalCost": 850.0,
    },
    {
        "name": "team-ml",
        "properties": {"namespace": "team-ml", "labels": {"finops.org/costcenter": "data-science"}},
        "cpuCost": 5000.0, "ramCost": 3000.0, "pvCost": 1000.0, "networkCost": 200.0,
        "totalCost": 9200.0,
    },
]

PERIOD = {"start": "2025-01-01T00:00:00+00:00", "end": "2025-01-31T23:59:59+00:00"}


class TestMonthToRange:
    def test_january(self):
        start, end = month_to_range("2025-01")
        assert start.startswith("2025-01-01")
        assert end.startswith("2025-01-31")

    def test_february_non_leap(self):
        start, end = month_to_range("2025-02")
        assert end.startswith("2025-02-28")

    def test_february_leap(self):
        start, end = month_to_range("2024-02")
        assert end.startswith("2024-02-29")

    def test_december(self):
        start, end = month_to_range("2025-12")
        assert end.startswith("2025-12-31")


class TestBuildReport:
    def _build(self, ns_costs=None):
        return build_report(
            SAMPLE_NS_COSTS if ns_costs is None else ns_costs,
            SHARED_COSTS_DEFAULT,
            "prod-cluster",
            "aws",
            PERIOD,
        )

    def test_report_has_required_fields(self):
        report = self._build()
        for key in ("report_id", "cost_centers", "shared_costs", "totals", "cluster_name"):
            assert key in report

    def test_cost_centers_aggregated(self):
        report = self._build()
        cc_names = [cc["cost_center"] for cc in report["cost_centers"]]
        assert "engineering" in cc_names
        assert "data-science" in cc_names

    def test_engineering_has_two_namespaces(self):
        report = self._build()
        eng = next(cc for cc in report["cost_centers"] if cc["cost_center"] == "engineering")
        assert set(eng["namespaces"]) == {"team-a", "team-b"}

    def test_engineering_cost_sum(self):
        report = self._build()
        eng = next(cc for cc in report["cost_centers"] if cc["cost_center"] == "engineering")
        assert eng["total_cost"] == 1800.0 + 850.0

    def test_shared_cost_allocation_sums_to_total(self):
        report = self._build()
        total_allocated = sum(cc["shared_cost_allocation"] for cc in report["cost_centers"])
        total_shared = sum(SHARED_COSTS_DEFAULT.values())
        assert abs(total_allocated - total_shared) < 0.01

    def test_untagged_namespace(self):
        ns_costs = SAMPLE_NS_COSTS + [
            {
                "name": "no-label-ns",
                "properties": {"namespace": "no-label-ns", "labels": {}},
                "cpuCost": 100.0, "ramCost": 50.0, "pvCost": 20.0, "networkCost": 10.0,
                "totalCost": 180.0,
            }
        ]
        report = self._build(ns_costs)
        cc_names = [cc["cost_center"] for cc in report["cost_centers"]]
        assert "untagged" in cc_names

    def test_sorted_by_cost_descending(self):
        report = self._build()
        costs = [cc["total_cost"] for cc in report["cost_centers"]]
        assert costs == sorted(costs, reverse=True)

    def test_empty_namespace_costs(self):
        report = self._build([])
        assert report["totals"]["cluster_total_usd"] == 0.0

    def test_currency_field(self):
        report = self._build()
        assert report["currency"] == "USD"

    def test_proportional_shared_allocation(self):
        """Higher-cost centers should receive a larger share of shared costs."""
        report = self._build()
        ds = next(cc for cc in report["cost_centers"] if cc["cost_center"] == "data-science")
        eng = next(cc for cc in report["cost_centers"] if cc["cost_center"] == "engineering")
        assert ds["shared_cost_allocation"] > eng["shared_cost_allocation"]


class TestReportToCsv:
    def _report(self):
        return build_report(SAMPLE_NS_COSTS, SHARED_COSTS_DEFAULT, "cluster", "aws", PERIOD)

    def test_csv_has_header(self):
        csv_str = report_to_csv(self._report())
        lines = csv_str.strip().split("\n")
        assert lines[0].startswith("report_id")

    def test_csv_rows_count(self):
        csv_str = report_to_csv(self._report())
        lines = [l for l in csv_str.strip().split("\n") if l]
        # 1 header + 3 namespace rows (team-a, team-b, team-ml)
        assert len(lines) == 4

    def test_csv_contains_engineering(self):
        csv_str = report_to_csv(self._report())
        assert "engineering" in csv_str

    def test_csv_contains_data_science(self):
        csv_str = report_to_csv(self._report())
        assert "data-science" in csv_str

    def test_csv_comma_separated(self):
        csv_str = report_to_csv(self._report())
        header_fields = csv_str.split("\n")[0].split(",")
        assert len(header_fields) >= 10
