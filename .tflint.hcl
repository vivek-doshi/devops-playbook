config {
  format = "compact"
  # Only the core Terraform language ruleset is enabled — no cloud provider
  # plugins — so this stays 100% offline and pre-commit never needs to
  # download a plugin binary.
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = false # repo uses mixed snake_case/kebab-case resource names by design
}
