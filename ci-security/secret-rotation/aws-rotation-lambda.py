"""
AWS Secrets Manager — Single-User Database Rotation Lambda
===========================================================
WHEN TO USE : Rotate a database password stored in AWS Secrets Manager.
              Works for PostgreSQL, MySQL, MariaDB.  Adapt the DB_ENGINE
              constant and the SQL statements for other engines.

HOW IT WORKS: Secrets Manager calls this Lambda at four lifecycle steps
              (createSecret → setSecret → testSecret → finishSecret).
              Each step is idempotent so a retry is safe.

PREREQUISITES:
  - The secret JSON must contain:
      { "username": "...", "password": "...",
        "host": "...", "port": 5432, "dbname": "..." }
  - Lambda must have network access to the database (VPC + SG rules).
  - Lambda execution role needs:
      secretsmanager:GetSecretValue
      secretsmanager:PutSecretValue
      secretsmanager:DescribeSecret
      secretsmanager:UpdateSecretVersionStage

WHAT TO CHANGE: Variables marked  # <-- CHANGE THIS
"""

import boto3
import json
import logging
import os
import secrets
import string
import psycopg2          # pip install psycopg2-binary  # <-- CHANGE THIS: use pymysql for MySQL

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# --- Configuration -------------------------------------------------------
DB_ENGINE    = "postgresql"   # <-- CHANGE THIS: "mysql" | "postgresql" | "mariadb"
PASSWORD_LEN = 32             # <-- CHANGE THIS: minimum 20 recommended
# Exclude characters that break DSN strings or shell quoting
EXCLUDED     = '"\'@/\\'
# -------------------------------------------------------------------------


def lambda_handler(event, context):
    """Entry point called by Secrets Manager at each rotation step."""
    arn   = event["SecretId"]
    token = event["ClientRequestToken"]
    step  = event["Step"]

    client = boto3.client("secretsmanager", region_name=os.environ["AWS_REGION"])

    metadata = client.describe_secret(SecretId=arn)
    if not metadata.get("RotationEnabled"):
        raise ValueError(f"Rotation is not enabled for secret {arn}")

    versions = metadata.get("VersionIdsToStages", {})
    if token not in versions:
        raise ValueError(f"Token {token} is not associated with secret {arn}")

    if "AWSCURRENT" in versions[token]:
        logger.info("Token is already AWSCURRENT — nothing to do")
        return
    if "AWSPENDING" not in versions[token]:
        raise ValueError(f"Token {token} is not in AWSPENDING stage")

    dispatch = {
        "createSecret": _create_secret,
        "setSecret":    _set_secret,
        "testSecret":   _test_secret,
        "finishSecret": _finish_secret,
    }
    if step not in dispatch:
        raise ValueError(f"Unknown step: {step}")

    dispatch[step](client, arn, token)


# ── Step 1: generate and store a new password in AWSPENDING ──────────────
def _create_secret(client, arn, token):
    try:
        client.get_secret_value(SecretId=arn, VersionStage="AWSPENDING",
                                VersionId=token)
        logger.info("createSecret: AWSPENDING already exists — skipping")
        return
    except client.exceptions.ResourceNotFoundException:
        pass

    current = _get_secret(client, arn, "AWSCURRENT")
    current["password"] = _generate_password()

    client.put_secret_value(
        SecretId=arn,
        ClientRequestToken=token,
        SecretString=json.dumps(current),
        VersionStages=["AWSPENDING"],
    )
    logger.info("createSecret: stored new password in AWSPENDING")


# ── Step 2: apply the new password in the actual database ────────────────
def _set_secret(client, arn, token):
    pending = _get_secret(client, arn, "AWSPENDING", token)
    current = _get_secret(client, arn, "AWSCURRENT")

    conn = _db_connect(current)
    try:
        with conn.cursor() as cur:
            if DB_ENGINE == "postgresql":
                cur.execute(
                    "ALTER USER %s WITH PASSWORD %s",
                    (pending["username"], pending["password"]),
                )
            else:
                # MySQL / MariaDB
                cur.execute(
                    "ALTER USER %s@'%%' IDENTIFIED BY %s",
                    (pending["username"], pending["password"]),
                )
        conn.commit()
        logger.info("setSecret: password updated in database")
    finally:
        conn.close()


# ── Step 3: verify the new credentials actually work ─────────────────────
def _test_secret(client, arn, token):
    pending = _get_secret(client, arn, "AWSPENDING", token)
    conn = _db_connect(pending)
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT 1")
        logger.info("testSecret: new credentials verified")
    finally:
        conn.close()


# ── Step 4: promote AWSPENDING to AWSCURRENT ─────────────────────────────
def _finish_secret(client, arn, token):
    metadata = client.describe_secret(SecretId=arn)
    current_version = next(
        (v for v, stages in metadata["VersionIdsToStages"].items()
         if "AWSCURRENT" in stages),
        None,
    )
    if current_version == token:
        logger.info("finishSecret: already AWSCURRENT — nothing to do")
        return

    client.update_secret_version_stage(
        SecretId=arn,
        VersionStage="AWSCURRENT",
        MoveToVersionId=token,
        RemoveFromVersionId=current_version,
    )
    logger.info("finishSecret: promoted AWSPENDING to AWSCURRENT")


# ── Helpers ───────────────────────────────────────────────────────────────
def _get_secret(client, arn, stage, version_id=None):
    kwargs = {"SecretId": arn, "VersionStage": stage}
    if version_id:
        kwargs["VersionId"] = version_id
    value = client.get_secret_value(**kwargs)
    return json.loads(value["SecretString"])


def _generate_password(length: int = PASSWORD_LEN) -> str:
    alphabet = string.ascii_letters + string.digits + string.punctuation
    safe = "".join(c for c in alphabet if c not in EXCLUDED)
    # Guarantee at least one of each required character class
    pwd = [
        secrets.choice(string.ascii_uppercase),
        secrets.choice(string.ascii_lowercase),
        secrets.choice(string.digits),
        secrets.choice("!#$%^&*()-_=+[]{}|;:,.<>?"),
    ]
    pwd += [secrets.choice(safe) for _ in range(length - len(pwd))]
    secrets.SystemRandom().shuffle(pwd)
    return "".join(pwd)


def _db_connect(secret: dict):
    if DB_ENGINE == "postgresql":
        return psycopg2.connect(
            host=secret["host"],
            port=secret.get("port", 5432),
            dbname=secret["dbname"],
            user=secret["username"],
            password=secret["password"],
            connect_timeout=5,
            sslmode="require",          # always require TLS in production
        )
    # MySQL / MariaDB
    import pymysql  # noqa: PLC0415
    return pymysql.connect(
        host=secret["host"],
        port=secret.get("port", 3306),
        db=secret["dbname"],
        user=secret["username"],
        password=secret["password"],
        connect_timeout=5,
        ssl={"ssl": True},
    )
