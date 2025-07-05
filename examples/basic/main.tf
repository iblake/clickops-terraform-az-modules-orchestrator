terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Create resource groups directly
resource "azurerm_resource_group" "rg" {
  for_each = var.iam_configuration.resource_groups
  
  name     = each.value.name
  location = each.value.location
  tags     = each.value.tags
}

# Create virtual networks directly
resource "azurerm_virtual_network" "vnet" {
  for_each = var.network_configuration.vnets
  
  name                = each.value.name
  location            = azurerm_resource_group.rg[each.value.resource_group_key].location
  resource_group_name = azurerm_resource_group.rg[each.value.resource_group_key].name
  address_space       = each.value.address_space
}

# Create subnets directly
resource "azurerm_subnet" "subnet" {
  for_each = merge([
    for vnet_key, vnet in var.network_configuration.vnets : {
      for subnet_key, subnet in vnet.subnets :
      "${vnet_key}-${subnet_key}" => {
        vnet_key = vnet_key
        subnet_key = subnet_key
        subnet = subnet
      }
    }
  ]...)
  
  name                 = each.value.subnet.name
  resource_group_name  = azurerm_resource_group.rg[var.network_configuration.vnets[each.value.vnet_key].resource_group_key].name
  virtual_network_name = azurerm_virtual_network.vnet[each.value.vnet_key].name
  address_prefixes     = each.value.subnet.address_prefixes
}

# Create virtual machines directly
resource "azurerm_linux_virtual_machine" "vm" {
  for_each = var.compute_configuration.vms
  
  name                = each.value.name
  resource_group_name = azurerm_resource_group.rg[each.value.resource_group_key].name
  location            = azurerm_resource_group.rg[each.value.resource_group_key].location
  size                = each.value.size
  admin_username      = each.value.admin_username

  network_interface_ids = [
    azurerm_network_interface.nic[each.key].id
  ]

  admin_ssh_key {
    username   = each.value.admin_username
    public_key = each.value.admin_ssh_key
  }

  os_disk {
    name                 = each.value.os_disk.name
    caching              = each.value.os_disk.caching
    storage_account_type = each.value.os_disk.storage_account_type
    disk_size_gb         = each.value.os_disk.disk_size_gb
  }

  source_image_reference {
    publisher = each.value.source_image_reference.publisher
    offer     = each.value.source_image_reference.offer
    sku       = each.value.source_image_reference.sku
    version   = each.value.source_image_reference.version
  }
}

# Create network interfaces
resource "azurerm_network_interface" "nic" {
  for_each = var.compute_configuration.vms
  
  name                = "${each.value.name}-nic"
  location            = azurerm_resource_group.rg[each.value.resource_group_key].location
  resource_group_name = azurerm_resource_group.rg[each.value.resource_group_key].name

  ip_configuration {
    name                          = each.value.network_interface.ip_configuration.name
    subnet_id                     = azurerm_subnet.subnet["test-vnet-${each.value.network_interface.subnet_key}"].id
    private_ip_address_allocation = each.value.network_interface.ip_configuration.private_ip_address_allocation
  }
}

variable "iam_configuration" {
  description = "IAM configuration object"
  type = object({
    resource_groups = map(object({
      name     = string
      location = string
      tags     = map(string)
    }))
  })
}

variable "network_configuration" {
  description = "Network configuration object"
  type = object({
    vnets = map(object({
      name              = string
      resource_group_key = string
      address_space     = list(string)
      subnets = map(object({
        name             = string
        address_prefixes = list(string)
      }))
    }))
  })
}

variable "compute_configuration" {
  description = "Compute configuration object"
  type = object({
    vms = map(object({
      name              = string
      resource_group_key = string
      size              = string
      admin_username    = string
      admin_ssh_key     = string
      os_disk = object({
        name                 = string
        caching              = string
        storage_account_type = string
        disk_size_gb        = number
      })
      source_image_reference = object({
        publisher = string
        offer     = string
        sku       = string
        version   = string
      })
      network_interface = object({
        subnet_key = string
        ip_configuration = object({
          name                          = string
          private_ip_address_allocation = string
          public_ip_address = optional(object({
            name              = string
            allocation_method = string
            sku              = string
          }))
        })
      })
    }))
  })
}

# Outputs
output "virtual_machines" {
  value = azurerm_linux_virtual_machine.vm
  sensitive = true
}

output "resource_groups" {
  value = azurerm_resource_group.rg
}

output "virtual_networks" {
  value = azurerm_virtual_network.vnet
}
