# Copyright (c) 2024 Blake and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Core storage
module "azure_lz_storage" {
  count = var.storage_configuration != null ? 1 : 0
  source = "./modules/storage"
  
  resource_groups = var.iam_configuration.resource_groups
  storage_accounts = var.storage_configuration.storage_accounts
  storage_containers = local.flattened_containers
  storage_shares = local.flattened_file_shares
} 