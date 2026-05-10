"""
finops/scripts/test_validate_cost_tags.py
Unit tests for validate-cost-tags.py

Run: pytest finops/scripts/test_validate_cost_tags.py -v
"""

import importlib.util
from pathlib import Path

_script = Path(__file__).parent / "validate-cost-tags.py"
_spec = importlib.util.spec_from_file_location("validate_cost_tags", _script)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)

validate_pod = _mod.validate_pod
build_report = _mod.build_report
REQUIRED_LABELS = _mod.REQUIRED_LABELS


def make_pod(name="pod-1", namespace="test-ns", labels=None):
    return {
        "metadata": {
            "name": name,
            "namespace": namespace,
            "labels": labels or {},
        }
    }


class TestValidatePod:
    def test_compliant_pod(self):
        pod = make_pod(labels={
            "finops.org/costcenter": "engineering",
            "finops.org/environment": "production",
        })
        result = validate_pod(pod)
        assert result["compliant"] is True
        assert result["missing_labels"] == []

    def test_missing_both_labels(self):
        result = validate_pod(make_pod(labels={}))
        assert result["compliant"] is False
        assert "finops.org/costcenter" in result["missing_labels"]
        assert "finops.org/environment" in result["missing_labels"]

    def test_missing_only_environment(self):
        pod = make_pod(labels={"finops.org/costcenter": "engineering"})
        result = validate_pod(pod)
        assert result["compliant"] is False
        assert result["missing_labels"] == ["finops.org/environment"]

    def test_missing_only_costcenter(self):
        pod = make_pod(labels={"finops.org/environment": "production"})
        result = validate_pod(pod)
        assert result["compliant"] is False
        assert result["missing_labels"] == ["finops.org/costcenter"]

    def test_extra_labels_dont_affect_compliance(self):
        pod = make_pod(labels={
            "finops.org/costcenter": "eng",
            "finops.org/environment": "dev",
            "app": "myapp",
            "team": "platform",
        })
        result = validate_pod(pod)
        assert result["compliant"] is True

    def test_empty_string_label_not_compliant(self):
        pod = make_pod(labels={
            "finops.org/costcenter": "",
            "finops.org/environment": "production",
        })
        result = validate_pod(pod)
        assert result["compliant"] is False

    def test_pod_fields_present(self):
        result = validate_pod(make_pod(name="my-pod", namespace="my-ns"))
        assert result["pod"] == "my-pod"
        assert result["namespace"] == "my-ns"

    def test_no_labels_field(self):
        pod = {"metadata": {"name": "test", "namespace": "default"}}
        result = validate_pod(pod)
        assert result["compliant"] is False
        assert len(result["missing_labels"]) == 2


class TestBuildReport:
    COMPLIANT_POD = make_pod("compliant", "ns-a", {
        "finops.org/costcenter": "engineering",
        "finops.org/environment": "production",
    })
    NON_COMPLIANT_POD = make_pod("non-compliant", "ns-b", {"app": "legacy"})

    def test_all_compliant(self):
        report = build_report([self.COMPLIANT_POD], "ns-a")
        assert report["summary"]["compliance_percentage"] == 100.0
        assert report["summary"]["is_compliant"] is True

    def test_some_non_compliant(self):
        report = build_report([self.COMPLIANT_POD, self.NON_COMPLIANT_POD], None)
        assert report["summary"]["compliance_percentage"] == 50.0
        assert report["summary"]["is_compliant"] is False

    def test_all_non_compliant(self):
        report = build_report([self.NON_COMPLIANT_POD], None)
        assert report["summary"]["compliance_percentage"] == 0.0
        assert report["summary"]["is_compliant"] is False

    def test_empty_pods(self):
        report = build_report([], None)
        assert report["summary"]["total_pods"] == 0
        assert report["summary"]["compliance_percentage"] == 100.0

    def test_non_compliant_by_namespace(self):
        report = build_report([self.NON_COMPLIANT_POD], None)
        assert "ns-b" in report["non_compliant_by_namespace"]
        assert report["non_compliant_by_namespace"]["ns-b"]["pod_count"] == 1

    def test_summary_counts(self):
        pods = [self.COMPLIANT_POD, self.COMPLIANT_POD, self.NON_COMPLIANT_POD]
        report = build_report(pods, None)
        s = report["summary"]
        assert s["total_pods"] == 3
        assert s["compliant_pods"] == 2
        assert s["non_compliant_pods"] == 1

    def test_95_threshold(self):
        # 95 compliant pods out of 100 → compliant
        pods = [
            make_pod(f"p{i}", "ns", {"finops.org/costcenter": "eng", "finops.org/environment": "prod"})
            for i in range(95)
        ] + [make_pod(f"nc{i}", "ns", {}) for i in range(5)]
        report = build_report(pods, "ns")
        assert report["summary"]["compliance_percentage"] == 95.0
        assert report["summary"]["is_compliant"] is True

    def test_report_structure(self):
        report = build_report([self.COMPLIANT_POD], None)
        assert "report_id" in report
        assert "generated_at" in report
        assert "non_compliant" in report
        assert "non_compliant_by_namespace" in report

    def test_namespace_filter(self):
        report = build_report([self.COMPLIANT_POD], "ns-a")
        assert report["scope"] == "ns-a"
