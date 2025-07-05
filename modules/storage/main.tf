# Resource Groups
resource "azurerm_resource_group" "rg" {
  for_each = var.resource_groups
  name     = each.value.name
  location = each.value.location
  tags     = each.value.tags
}

# Storage Accounts
resource "azurerm_storage_account" "storage" {
  for_each = var.storage_accounts
  name                     = each.value.name
  resource_group_name      = var.resource_groups[each.value.resource_group_key].name
  location                 = var.resource_groups[each.value.resource_group_key].location
  account_tier             = each.value.account_tier
  account_replication_type = each.value.account_replication_type
  account_kind             = each.value.account_kind
  tags                     = try(each.value.tags, null)
}

# Storage Containers
resource "azurerm_storage_container" "container" {
  for_each = var.storage_containers
  name                  = each.value.name
  storage_account_name  = azurerm_storage_account.storage[each.value.storage_account_key].name
  container_access_type = each.value.container_access_type
}

# Storage File Shares
resource "azurerm_storage_share" "share" {
  for_each = var.storage_shares
  name                 = each.value.name
  storage_account_name = azurerm_storage_account.storage[each.value.storage_account_key].name
  quota                = each.value.quota_in_gb
}
