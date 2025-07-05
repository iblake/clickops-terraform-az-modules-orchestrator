# Storage Accounts
output "storage_accounts" {
  description = "Map of created storage accounts"
  value = {
    for k, v in azurerm_storage_account.storage : k => {
      id                      = v.id
      name                    = v.name
      resource_group          = v.resource_group_name
      location                = v.location
      account_tier            = v.account_tier
      account_replication_type = v.account_replication_type
      primary_access_key      = v.primary_access_key
      primary_blob_endpoint   = v.primary_blob_endpoint
      tags                    = v.tags
    }
  }
}

# Storage Containers
output "storage_containers" {
  description = "Map of created storage containers"
  value = {
    for k, v in azurerm_storage_container.container : k => {
      id             = v.id
      name           = v.name
      storage_account = v.storage_account_name
      access_type    = v.container_access_type
    }
  }
}

# Storage File Shares
output "storage_shares" {
  description = "Map of created storage file shares"
  value = {
    for k, v in azurerm_storage_share.share : k => {
      id             = v.id
      name           = v.name
      storage_account = v.storage_account_name
      quota          = v.quota
    }
  }
}
