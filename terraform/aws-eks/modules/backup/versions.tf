# This module is called with a second "aws.dr_region" provider alias for the
# cross-region read replica — declared as a configuration alias here.
terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.dr_region]
    }
  }
}
