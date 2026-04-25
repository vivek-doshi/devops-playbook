# ============================================================
# TEMPLATE: Azure Key Vault — Near-Expiry Secret Rotation
# WHEN TO USE: Automatically rotate a secret in Azure Key Vault
#              before it expires, triggered by an EventGrid event.
# PREREQUISITES:
#   - Azure Key Vault with an existing secret that has an expiry date set.
#   - Azure Function App (Consumption or Flex) with system-assigned identity.
#   - Function app identity must have "Key Vault Secrets Officer" on the vault.
# WHAT TO CHANGE: Lines marked  # <-- CHANGE THIS
# RELATED FILES: security/secret-rotation/external-secrets-operator.yaml
# MATURITY: Stable
# ============================================================

# ---------------------------------------------
# 1. EventGrid System Topic — Key Vault events
# ---------------------------------------------
resource "azurerm_eventgrid_system_topic" "keyvault" {
  name                   = "evgt-kv-rotation"       # <-- CHANGE THIS
  resource_group_name    = var.resource_group_name
  location               = var.location
  source_arm_resource_id = var.key_vault_id
  topic_type             = "Microsoft.KeyVault.vaults"
  tags                   = var.common_tags
}

# ---------------------------------------------
# 2. EventGrid Subscription → Azure Function
# ---------------------------------------------
resource "azurerm_eventgrid_system_topic_event_subscription" "near_expiry" {
  name                = "sub-kv-secret-near-expiry"
  system_topic        = azurerm_eventgrid_system_topic.keyvault.name
  resource_group_name = var.resource_group_name

  # Fire when a secret is about to expire (30-day warning)
  included_event_types = [
    "Microsoft.KeyVault.SecretNearExpiry",
    "Microsoft.KeyVault.SecretExpired",
  ]

  azure_function_endpoint {
    function_id = "${var.function_app_id}/functions/RotateSecret"
    # Ensure the function endpoint uses the same auth as the Event Grid topic
    max_events_per_batch              = 1
    preferred_batch_size_in_kilobytes = 64
  }

  retry_policy {
    max_delivery_attempts = 10
    event_time_to_live    = 1440 # 24 hours
  }
}

# Grant EventGrid permission to invoke the function
resource "azurerm_role_assignment" "eventgrid_to_function" {
  scope                = var.function_app_id
  role_definition_name = "Website Contributor"
  principal_id         = azurerm_eventgrid_system_topic.keyvault.identity[0].principal_id
}

# Grant Function identity access to Key Vault
resource "azurerm_role_assignment" "function_kv_secrets_officer" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.function_identity_principal_id # <-- CHANGE THIS: system-assigned MI principal
}

# ============================================================
# Azure Function code (Python) — save as function_app.py
# ============================================================
# The Terraform above wires up the trigger.  The function body below
# lives in your Function App repository.  It is included here for
# reference so both pieces land together in code review.
#
# import azure.functions as func
# import json, logging, os
# from datetime import datetime, timezone, timedelta
# from azure.identity import ManagedIdentityCredential
# from azure.keyvault.secrets import SecretClient
#
# app = func.FunctionApp()
# VAULT_URL = os.environ["KEY_VAULT_URL"]   # <-- CHANGE THIS: set as App Setting
#
# @app.event_grid_trigger(arg_name="event")
# def RotateSecret(event: func.EventGridEvent):
#     data = event.get_json()
#     secret_name = data["ObjectName"]
#     logging.info(f"Rotating secret: {secret_name}")
#
#     client = SecretClient(
#         vault_url=VAULT_URL,
#         credential=ManagedIdentityCredential(),
#     )
#     current = client.get_secret(secret_name)
#
#     # ── Replace this block with your actual rotation logic ──────────────
#     # Example: regenerate a database password and update the upstream DB
#     new_value = _regenerate_value(current.value)
#     # _update_upstream_system(secret_name, new_value)
#     # ────────────────────────────────────────────────────────────────────
#
#     expiry = datetime.now(timezone.utc) + timedelta(days=90)
#     client.set_secret(
#         secret_name,
#         new_value,
#         expires_on=expiry,
#         content_type=current.properties.content_type,
#     )
#     logging.info(f"Secret {secret_name} rotated; new expiry {expiry.isoformat()}")
#
# def _regenerate_value(current_value: str) -> str:
#     # TODO: implement — call DB API, external provider, etc.
#     raise NotImplementedError("Implement rotation logic for your secret type")

# ---------------------------------------------
# Variables expected by this module
# ---------------------------------------------
variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "key_vault_id"        { type = string }
variable "function_app_id"     { type = string }
variable "function_identity_principal_id" { type = string }
variable "common_tags"         { type = map(string); default = {} }
