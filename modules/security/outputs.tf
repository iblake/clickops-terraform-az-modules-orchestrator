# Key Vaults
output "key_vaults" {
  description = "Map of created key vaults"
  value = {
    for k, v in azurerm_key_vault.vault : k => {
      id                      = v.id
      name                    = v.name
      resource_group          = v.resource_group_name
      location                = v.location
      tenant_id               = v.tenant_id
      sku_name                = v.sku_name
      vault_uri               = v.vault_uri
      tags                    = v.tags
    }
  }
}
