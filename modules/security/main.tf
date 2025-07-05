# Resource Groups
resource "azurerm_resource_group" "rg" {
  for_each = var.resource_groups
  name     = each.value.name
  location = each.value.location
  tags     = each.value.tags
}

# Key Vaults
resource "azurerm_key_vault" "vault" {
  for_each = var.key_vaults
  name                = each.value.name
  location            = var.resource_groups[each.value.resource_group_key].location
  resource_group_name = var.resource_groups[each.value.resource_group_key].name
  tenant_id           = each.value.tenant_id
  sku_name            = each.value.sku_name
  tags                = try(each.value.tags, null)
  dynamic "access_policy" {
    for_each = try(each.value.access_policies, [])
    content {
      tenant_id               = access_policy.value.tenant_id
      object_id               = access_policy.value.object_id
      key_permissions         = access_policy.value.key_permissions
      secret_permissions      = access_policy.value.secret_permissions
      certificate_permissions = access_policy.value.certificate_permissions
    }
  }
}
