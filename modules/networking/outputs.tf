# Resource Groups
output "resource_groups" {
  description = "Map of created resource groups"
  value = {
    for k, v in azurerm_resource_group.rg : k => {
      id       = v.id
      name     = v.name
      location = v.location
      tags     = v.tags
    }
  }
}

# Virtual Networks
output "virtual_networks" {
  description = "Map of created virtual networks"
  value = {
    for k, v in azurerm_virtual_network.vnet : k => {
      id              = v.id
      name            = v.name
      resource_group  = v.resource_group_name
      location        = v.location
      address_space   = v.address_space
      tags            = v.tags
    }
  }
}

# Subnets
output "subnets" {
  description = "Map of created subnets"
  value = {
    for k, v in azurerm_subnet.subnet : k => {
      id                 = v.id
      name               = v.name
      resource_group     = v.resource_group_name
      virtual_network    = v.virtual_network_name
      address_prefixes   = v.address_prefixes
    }
  }
}

# Network Security Groups
output "network_security_groups" {
  description = "Map of created network security groups"
  value = {
    for k, v in azurerm_network_security_group.nsg : k => {
      id             = v.id
      name           = v.name
      location       = v.location
      resource_group = v.resource_group_name
      tags           = v.tags
    }
  }
}
