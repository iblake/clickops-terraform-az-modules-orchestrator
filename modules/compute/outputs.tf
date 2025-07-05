output "virtual_machines" {
  description = "Map of created virtual machines"
  value = {
    for k, v in azurerm_linux_virtual_machine.vm : k => {
      id                  = v.id
      name                = v.name
      resource_group_name = v.resource_group_name
      location            = v.location
      private_ip_address  = azurerm_network_interface.nic[k].private_ip_address
      public_ip_address   = try(azurerm_public_ip.vm[k].ip_address, null)
    }
  }
}

output "network_interfaces" {
  description = "Map of created network interfaces"
  value = {
    for k, v in azurerm_network_interface.nic : k => {
      id                = v.id
      name              = v.name
      private_ip_address = v.private_ip_address
    }
  }
}

output "public_ips" {
  description = "Map of created public IPs"
  value = {
    for k, v in azurerm_public_ip.vm : k => {
      id           = v.id
      name         = v.name
      ip_address   = v.ip_address
    }
  }
} 