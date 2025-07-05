# Copyright (c) 2024 Blake and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Virtual Networks
resource "azurerm_virtual_network" "these" {
  for_each = var.network_configuration != null ? (
    var.network_configuration.vnets != null ? var.network_configuration.vnets : {}
  ) : {}

  name                = each.value.name
  location            = azurerm_resource_group.these[each.value.resource_group_key].location
  resource_group_name = azurerm_resource_group.these[each.value.resource_group_key].name
  address_space       = each.value.address_space
  dns_servers         = try(each.value.dns_servers, null)
  tags                = try(each.value.tags, null)
}

# Subnets
resource "azurerm_subnet" "these" {
  for_each = local.flattened_subnets

  name                 = each.value.name
  resource_group_name  = azurerm_resource_group.these[each.value.resource_group_key].name
  virtual_network_name = azurerm_virtual_network.these[each.value.vnet_key].name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = try(each.value.service_endpoints, null)

  dynamic "delegation" {
    for_each = try(each.value.delegation, {})
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.name
        actions = delegation.value.actions
      }
    }
  }
}

# Network Security Groups
resource "azurerm_network_security_group" "these" {
  for_each = var.network_configuration != null ? (
    var.network_configuration.network_security_groups != null ? var.network_configuration.network_security_groups : {}
  ) : {}

  name                = each.value.name
  location            = azurerm_resource_group.these[each.value.resource_group_key].location
  resource_group_name = azurerm_resource_group.these[each.value.resource_group_key].name
  tags                = try(each.value.tags, null)

  dynamic "security_rule" {
    for_each = try(each.value.rules, [])
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range         = security_rule.value.source_port_range
      destination_port_range    = security_rule.value.destination_port_range
      source_address_prefix     = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}

# NSG Association
resource "azurerm_subnet_network_security_group_association" "these" {
  for_each = {
    for subnet_key, subnet in local.flattened_subnets :
    subnet_key => subnet
    if try(subnet.security_group, null) != null
  }

  subnet_id                 = azurerm_subnet.these[each.key].id
  network_security_group_id = azurerm_network_security_group.these[each.value.security_group].id
} 