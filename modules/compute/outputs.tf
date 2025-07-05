output "virtual_machines" {
  description = "Details of all virtual machines created"
  value = {
    for k, v in azurerm_linux_virtual_machine.vm : k => {
      id                 = v.id
      name               = v.name
      resource_group     = v.resource_group_name
      location          = v.location
      size              = v.size
      admin_username    = v.admin_username
      private_ip        = azurerm_network_interface.nic[k].private_ip_address
      public_ip         = try(azurerm_public_ip.pip[k].ip_address, null)
    }
  }
} 