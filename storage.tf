# Copyright (c) 2024 Blake and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Storage Accounts
resource "azurerm_storage_account" "these" {
  for_each = var.storage_configuration != null ? (
    var.storage_configuration.storage_accounts != null ? var.storage_configuration.storage_accounts : {}
  ) : {}

  name                     = each.value.name
  resource_group_name      = azurerm_resource_group.these[each.value.resource_group_key].name
  location                 = azurerm_resource_group.these[each.value.resource_group_key].location
  account_tier            = each.value.account_tier
  account_replication_type = each.value.account_replication_type
  account_kind           = each.value.account_kind
  tags                    = try(each.value.tags, null)
}

# Storage Containers
resource "azurerm_storage_container" "these" {
  for_each = local.flattened_containers

  name                  = each.value.name
  storage_account_name  = azurerm_storage_account.these[each.value.storage_account_key].name
  container_access_type = each.value.container_access_type
}

# Storage File Shares
resource "azurerm_storage_share" "these" {
  for_each = local.flattened_file_shares

  name                 = each.value.name
  storage_account_name = azurerm_storage_account.these[each.value.storage_account_key].name
  quota                = each.value.quota_in_gb
} 