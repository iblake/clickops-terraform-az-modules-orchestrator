# Copyright (c) 2024 Blake and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Public IPs for VMs (if configured)
resource "azurerm_public_ip" "vm" {
  for_each = {
    for k, v in var.configuration.vms : k => v
    if try(v.public_ip, null) != null
  }

  name                = each.value.public_ip.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  allocation_method   = each.value.public_ip.allocation_method
  sku                = each.value.public_ip.sku
  tags               = try(each.value.tags, null)
}

# Network Interfaces
resource "azurerm_network_interface" "nic" {
  for_each = var.configuration.vms

  name                = "${each.value.name}-nic"
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  tags                = try(each.value.tags, null)

  ip_configuration {
    name                          = "internal"
    subnet_id                     = each.value.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id         = try(each.value.public_ip, null) != null ? azurerm_public_ip.vm[each.key].id : null
  }
}

# Linux Virtual Machines
resource "azurerm_linux_virtual_machine" "vm" {
  for_each = var.configuration.vms

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
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