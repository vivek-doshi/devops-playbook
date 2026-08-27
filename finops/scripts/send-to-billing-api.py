#!/usr/bin/env python3
"""
finops/scripts/send-to-billing-api.py
Example integration for posting monthly cost chargeback data to an
enterprise billing API.  Includes OAuth2 client-credentials auth,
API-key auth, retry logic, and dry-run mode.

Usage:
  python send-to-billing-api.py --report finops/reports/cost-report-2025-04.json
  python send-to-billing-api.py --report report.json --auth-type api-key --dry-run

Environment variables (or use CLI flags):
  BILLING_API_URL       Base URL of the enterprise billing API
  BILLING_CLIENT_ID     OAuth2 client ID
  BILLING_CLIENT_SECRET OAuth2 client secret
  BILLING_API_KEY       API key (alternative to OAuth2)
  BILLING_TENANT_ID     OAuth2 tenant / token endpoint base

Requirements:
  pip install requests
"""

import argparse
import json
import os
import sys
import time
from typing import Any

# ─── Constants ────────────────────────────────────────────────────────────────

DEFAULT_TIMEOUT = 30  # seconds per request
MAX_RETRIES = 3
RETRY_BACKOFF = 2  # seconds (doubles each retry)


# ─── Authentication helpers ───────────────────────────────────────────────────


def get_oauth2_token(
    token_url: str,
    client_id: str,
    client_secret: str,
    scope: str = "billing.write",
) -> str:
    """Obtain a Bearer token via OAuth2 client-credentials flow."""
    import requests  # noqa: PLC0415

    resp = requests.post(
        token_url,
        data={
            "grant_type": "client_credentials",
            "client_id": client_id,
            "client_secret": client_secret,
            "scope": scope,
        },
        timeout=DEFAULT_TIMEOUT,
    )
    resp.raise_for_status()
    token = resp.json().get("access_token")
    if not token:
        raise ValueError(f"No access_token in response: {resp.text[:200]}")
    print(f"  [auth] OAuth2 token obtained (expires_in={resp.json().get('expires_in', '?')}s)")
    return token


def build_headers(auth_type: str, credential: str) -> dict[str, str]:
    """Build HTTP headers for the chosen auth type."""
    if auth_type == "oauth2":
        return {
            "Authorization": f"Bearer {credential}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        }
    elif auth_type == "api-key":
        return {
            "X-API-Key": credential,
            "Content-Type": "application/json",
            "Accept": "application/json",
        }
    raise ValueError(f"Unknown auth type: {auth_type}")


# ─── API submission ───────────────────────────────────────────────────────────


def post_with_retry(
    url: str,
    payload: dict[str, Any],
    headers: dict[str, str],
    dry_run: bool,
) -> dict[str, Any]:
    """POST payload to API URL with exponential-backoff retry on transient errors."""
    import requests  # noqa: PLC0415

    if dry_run:
        print(f"  [dry-run] Would POST to: {url}")
        print(f"  [dry-run] Payload preview: {json.dumps(payload)[:300]}...")
        return {"status": "dry-run", "message": "Not sent"}

    last_exc: Exception | None = None
    backoff = RETRY_BACKOFF

    for attempt in range(1, MAX_RETRIES + 1):
        try:
            resp = requests.post(url, json=payload, headers=headers, timeout=DEFAULT_TIMEOUT)

            if resp.status_code == 429:
                retry_after = int(resp.headers.get("Retry-After", backoff))
                print(f"  [retry] Rate limited — waiting {retry_after}s ...")
                time.sleep(retry_after)
                continue

            if resp.status_code >= 500:
                raise requests.HTTPError(f"Server error {resp.status_code}: {resp.text[:200]}")

            resp.raise_for_status()
            return resp.json()

        except requests.RequestException as exc:
            last_exc = exc
            if attempt < MAX_RETRIES:
                print(f"  [retry] Attempt {attempt} failed: {exc}. Retrying in {backoff}s ...")
                time.sleep(backoff)
                backoff *= 2
            else:
                print(f"  [error] All {MAX_RETRIES} attempts failed.")

    raise RuntimeError(f"Failed to POST after {MAX_RETRIES} retries: {last_exc}")


# ─── Payload builder ──────────────────────────────────────────────────────────


def build_payload(report: dict[str, Any], cluster_name: str) -> list[dict[str, Any]]:
    """
    Transform the cost report JSON into the billing API line-item format.

    Expected billing API schema (adjust to match your enterprise system):
      {
        "cost_center": str,
        "billing_period": "YYYY-MM",
        "cluster": str,
        "total_cost_usd": float,
        "compute_cost_usd": float,
        "storage_cost_usd": float,
        "network_cost_usd": float,
        "shared_cost_allocation_usd": float,
        "namespaces": [str]
      }
    """
    line_items = []
    billing_period = report.get("month", "unknown")

    for entry in report.get("cost_centers", []):
        line_items.append(
            {
                "cost_center": entry.get("cost_center", "unknown"),
                "billing_period": billing_period,
                "cluster": cluster_name,
                "total_cost_usd": round(entry.get("total_cost_usd", 0), 4),
                "compute_cost_usd": round(entry.get("compute_cost_usd", 0), 4),
                "storage_cost_usd": round(entry.get("storage_cost_usd", 0), 4),
                "network_cost_usd": round(entry.get("network_cost_usd", 0), 4),
                "shared_cost_allocation_usd": round(entry.get("shared_cost_usd", 0), 4),
                "namespaces": entry.get("namespaces", []),
            }
        )

    return line_items


# ─── Main ─────────────────────────────────────────────────────────────────────


def main() -> None:
    parser = argparse.ArgumentParser(description="Send cost report to enterprise billing API")
    parser.add_argument("--report", required=True, help="Path to cost-report JSON file")
    parser.add_argument(
        "--api-url", default=os.environ.get("BILLING_API_URL", ""), help="Billing API base URL"
    )
    parser.add_argument("--auth-type", choices=["oauth2", "api-key"], default="oauth2")
    parser.add_argument("--client-id", default=os.environ.get("BILLING_CLIENT_ID", ""))
    parser.add_argument("--client-secret", default=os.environ.get("BILLING_CLIENT_SECRET", ""))
    parser.add_argument("--api-key", default=os.environ.get("BILLING_API_KEY", ""))
    parser.add_argument("--tenant-id", default=os.environ.get("BILLING_TENANT_ID", ""))
    parser.add_argument("--cluster-name", default=os.environ.get("CLUSTER_NAME", "production"))
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    # Validate inputs
    if not args.api_url and not args.dry_run:
        print("ERROR: --api-url or BILLING_API_URL is required (unless --dry-run)")
        sys.exit(1)

    # Load report
    print(f"==> Loading report: {args.report}")
    with open(args.report) as f:
        report = json.load(f)
    billing_period = report.get("month", "unknown")
    print(f"    Billing period : {billing_period}")
    print(f"    Cluster        : {args.cluster_name}")

    # Authenticate
    if not args.dry_run:
        if args.auth_type == "oauth2":
            if not (args.client_id and args.client_secret):
                print("ERROR: OAuth2 requires --client-id and --client-secret")
                sys.exit(1)
            token_url = (
                f"https://login.microsoftonline.com/{args.tenant_id}/oauth2/v2.0/token"
                if args.tenant_id
                else f"{args.api_url}/oauth2/token"
            )
            credential = get_oauth2_token(token_url, args.client_id, args.client_secret)
        else:
            credential = args.api_key
            if not credential:
                print("ERROR: API-key auth requires --api-key or BILLING_API_KEY")
                sys.exit(1)
    else:
        credential = "dry-run-token"

    headers = build_headers(args.auth_type, credential)

    # Build and send payload
    line_items = build_payload(report, args.cluster_name)
    print(f"\n==> Submitting {len(line_items)} cost-center line item(s) ...")

    endpoint = f"{args.api_url}/api/v1/cost-allocations/bulk"
    result = post_with_retry(
        endpoint,
        {"billing_period": billing_period, "cluster": args.cluster_name, "line_items": line_items},
        headers,
        args.dry_run,
    )

    print(f"\n==> Success.")
    print(f"    Response: {json.dumps(result, indent=2)[:400]}")


if __name__ == "__main__":
    main()
