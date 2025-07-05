# Copyright (c) 2024 Blake and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Key Vaults
resource "azurerm_key_vault" "these" {
  for_each = var.security_configuration != null ? (
    var.security_configuration.key_vaults != null ? var.security_configuration.key_vaults : {}
  ) : {}

  name                = each.value.name
  location            = azurerm_resource_group.these[each.value.resource_group_key].location
  resource_group_name = azurerm_resource_group.these[each.value.resource_group_key].name
  tenant_id          = each.value.tenant_id
  sku_name           = each.value.sku_name
  tags               = try(each.value.tags, null)

  dynamic "access_policy" {
    for_each = try(each.value.access_policies, [])
    content {
      tenant_id               = access_policy.value.tenant_id
      object_id              = access_policy.value.object_id
      key_permissions        = access_policy.value.key_permissions
      secret_permissions     = access_policy.value.secret_permissions
      certificate_permissions = access_policy.value.certificate_permissions
    }
  }
}

# Bastion Hosts
resource "azurerm_bastion_host" "these" {
  for_each = var.security_configuration != null ? (
    var.security_configuration.bastions != null ? var.security_configuration.bastions : {}
  ) : {}

  name                = each.value.name
  location            = azurerm_resource_group.these[each.value.resource_group_key].location
  resource_group_name = azurerm_resource_group.these[each.value.resource_group_key].name
  tags                = try(each.value.tags, null)

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.these["${each.value.vnet_key}-${each.value.subnet_key}"].id
    public_ip_address_id = azurerm_public_ip.bastion[each.key].id
  }
}

# Public IPs for Bastion
resource "azurerm_public_ip" "bastion" {
  for_each = var.security_configuration != null ? (
    var.security_configuration.bastions != null ? var.security_configuration.bastions : {}
  ) : {}

  name                = each.value.public_ip_name
  location            = azurerm_resource_group.these[each.value.resource_group_key].location
  resource_group_name = azurerm_resource_group.these[each.value.resource_group_key].name
  allocation_method   = "Static"
  sku                = "Standard"
  tags               = try(each.value.tags, null)
} 