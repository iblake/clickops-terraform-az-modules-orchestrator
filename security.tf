# Copyright (c) 2024 Blake and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Core security
module "azure_lz_security" {
  count = var.security_configuration != null ? 1 : 0
  source = "./modules/security"
  
  resource_groups = var.iam_configuration.resource_groups
  key_vaults = var.security_configuration.key_vaults
} 