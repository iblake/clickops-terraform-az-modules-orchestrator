# Copyright (c) 2024 Blake and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Network Interfaces
resource "azurerm_network_interface" "nic" {
  for_each = var.vms

  name                = try(each.value.network_interface.name, "${each.value.name}-nic")
  location            = coalesce(try(each.value.location, null), var.resource_groups[each.value.resource_group_key].location)
  resource_group_name = var.resource_groups[each.value.resource_group_key].name
  tags                = try(each.value.tags, null)

  ip_configuration {
    name                          = try(each.value.network_interface.ip_configuration.name, "internal")
    subnet_id                     = var.subnets["${var.get_vnet_key_for_subnet[each.value.network_interface.subnet_key]}-${each.value.network_interface.subnet_key}"].id
    private_ip_address_allocation = each.value.network_interface.ip_configuration.private_ip_address_allocation
    private_ip_address           = try(each.value.network_interface.ip_configuration.private_ip_address, null)
    public_ip_address_id         = try(each.value.network_interface.ip_configuration.public_ip_address, null) != null ? azurerm_public_ip.vm[each.key].id : null
  }
}

# Public IPs for VMs (if configured)
resource "azurerm_public_ip" "vm" {
  for_each = {
    for k, v in var.vms : k => v
    if try(v.network_interface.ip_configuration.public_ip_address, null) != null
  }

  name                = each.value.network_interface.ip_configuration.public_ip_address.name
  location            = coalesce(try(each.value.location, null), var.resource_groups[each.value.resource_group_key].location)
  resource_group_name = var.resource_groups[each.value.resource_group_key].name
  allocation_method   = each.value.network_interface.ip_configuration.public_ip_address.allocation_method
  sku                = each.value.network_interface.ip_configuration.public_ip_address.sku
  tags               = try(each.value.network_interface.ip_configuration.public_ip_address.tags, null)
}

# Linux Virtual Machines
resource "azurerm_linux_virtual_machine" "vm" {
  for_each = var.vms

  name                = each.value.name
  resource_group_name = var.resource_groups[each.value.resource_group_key].name
  location            = coalesce(try(each.value.location, null), var.resource_groups[each.value.resource_group_key].location)
  size                = each.value.size
  admin_username      = each.value.admin_username
  tags                = try(each.value.tags, null)

  network_interface_ids = [
    azurerm_network_interface.nic[each.key].id
  ]

  admin_ssh_key {
    username   = each.value.admin_username
    public_key = each.value.admin_ssh_key
  }

  os_disk {
    name                 = try(each.value.os_disk.name, "${each.value.name}-osdisk")
    caching              = each.value.os_disk.caching
    storage_account_type = each.value.os_disk.storage_account_type
    disk_size_gb        = each.value.os_disk.disk_size_gb
  }

  source_image_reference {
    publisher = each.value.source_image_reference.publisher
    offer     = each.value.source_image_reference.offer
    sku       = each.value.source_image_reference.sku
    version   = each.value.source_image_reference.version
  }
} 