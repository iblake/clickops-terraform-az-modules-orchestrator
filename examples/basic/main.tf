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
  
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
}

variable "subscription_id" {
  description = "The Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "The Azure Tenant ID"
  type        = string
  sensitive   = true
}

variable "client_id" {
  description = "The Azure Client ID"
  type        = string
  sensitive   = true
}

variable "client_secret" {
  description = "The Azure Client Secret"
  type        = string
  sensitive   = true
}

module "compute" {
  source = "../../modules/compute"

  configuration = {
    vms = {
      for k, v in var.compute_configuration.vms : k => {
        name                = v.name
        resource_group_id   = v.resource_group_key
        subnet_id          = "${v.resource_group_key}-${v.network_interface.subnet_key}"
        size               = v.size
        admin_username     = v.admin_username
        admin_ssh_key      = v.admin_ssh_key
        public_ip         = try(v.network_interface.ip_configuration.public_ip_address != null, false)
        os_disk            = v.os_disk
        source_image_reference = v.source_image_reference
      }
    }
  }

  resource_group_ids = {
    for k, v in var.iam_configuration.resource_groups : k => v.name
  }

  subnet_ids = {
    for k, v in var.network_configuration.vnets : "${k}-${v.subnets[keys(v.subnets)[0]].name}" => "${v.name}/${v.subnets[keys(v.subnets)[0]].name}"
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
  value = module.compute.virtual_machines
}
