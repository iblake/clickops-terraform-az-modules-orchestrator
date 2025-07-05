# Resource Groups
resource "azurerm_resource_group" "rg" {
  for_each = var.resource_groups
  name     = each.value.name
  location = each.value.location
  tags     = each.value.tags
}

# Virtual Networks
resource "azurerm_virtual_network" "vnet" {
  for_each = var.vnets
  name                = each.value.name
  location            = var.resource_groups[each.value.resource_group_key].location
  resource_group_name = var.resource_groups[each.value.resource_group_key].name
  address_space       = each.value.address_space
  dns_servers         = try(each.value.dns_servers, null)
  tags                = try(each.value.tags, null)
}

# Subnets
resource "azurerm_subnet" "subnet" {
  for_each = var.subnets
  name                 = each.value.name
  resource_group_name  = var.resource_groups[each.value.resource_group_key].name
  virtual_network_name = azurerm_virtual_network.vnet[each.value.vnet_key].name
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
resource "azurerm_network_security_group" "nsg" {
  for_each = var.network_security_groups
  name                = each.value.name
  location            = var.resource_groups[each.value.resource_group_key].location
  resource_group_name = var.resource_groups[each.value.resource_group_key].name
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

# Subnet to NSG Associations
resource "azurerm_subnet_network_security_group_association" "subnet_nsg" {
  for_each = {
    for subnet_key, subnet in var.subnets :
    subnet_key => subnet
    if try(subnet.security_group, null) != null
  }
  subnet_id                 = azurerm_subnet.subnet[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.value.security_group].id
}
