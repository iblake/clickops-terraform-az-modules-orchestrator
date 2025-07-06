# Copyright (c) 2024 Blake and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Core IAM
module "azure_lz_iam" {
  count = var.iam_configuration != null ? 1 : 0
  source = "./modules/iam"
  
  resource_groups = var.iam_configuration.resource_groups
  roles = var.iam_configuration.roles
  role_assignments = var.iam_configuration.role_assignments
  subscription_id = local.subscription_id
} 