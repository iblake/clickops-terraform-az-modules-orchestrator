# Azure Orchestrator Variables

# Authentication Variables
variable "subscription_id" {
  description = "The Azure Subscription ID"
  type        = string
  default     = null
}

variable "tenant_id" {
  description = "The Azure Tenant ID"
  type        = string
  default     = null
}

variable "client_id" {
  description = "The Azure Client ID"
  type        = string
  default     = null
}

variable "client_secret" {
  description = "The Azure Client Secret"
  type        = string
  default     = null
}

# IAM Configuration
variable "iam_configuration" {
  description = "Configuration for IAM resources including resource groups, roles, and role assignments"
  type = object({
    resource_groups = optional(map(object({
      name     = string
      location = optional(string)
      tags     = optional(map(string))
    })))
    roles = optional(map(object({
      name        = string
      description = string
      permissions = list(object({
        actions          = list(string)
        not_actions      = optional(list(string))
        data_actions     = optional(list(string))
        not_data_actions = optional(list(string))
      }))
    })))
    role_assignments = optional(map(object({
      role_name    = string
      principal_id = string
      scope        = string
    })))
  })
  default = null
}

# Network Configuration
variable "network_configuration" {
  description = "Configuration for network resources including virtual networks, subnets, and network security groups"
  type = object({
    vnets = optional(map(object({
      name                = string
      resource_group_key = string
      address_space      = list(string)
      dns_servers        = optional(list(string))
      subnets = optional(map(object({
        name              = string
        address_prefixes  = list(string)
        security_group    = optional(string)
        service_endpoints = optional(list(string))
        delegation = optional(map(object({
          name    = string
          actions = list(string)
        })))
      })))
      tags = optional(map(string))
    })))
    network_security_groups = optional(map(object({
      name               = string
      resource_group_key = string
      rules = optional(list(object({
        name                       = string
        priority                   = number
        direction                  = string
        access                     = string
        protocol                   = string
        source_port_range         = string
        destination_port_range    = string
        source_address_prefix     = string
        destination_address_prefix = string
      })))
      tags = optional(map(string))
    })))
  })
  default = null
}

# Security Configuration
variable "security_configuration" {
  description = "Configuration for security resources including key vaults and bastion hosts"
  type = object({
    key_vaults = optional(map(object({
      name                = string
      resource_group_key = string
      sku_name           = string
      tenant_id          = string
      access_policies = optional(list(object({
        tenant_id               = string
        object_id              = string
        key_permissions        = list(string)
        secret_permissions     = list(string)
        certificate_permissions = list(string)
      })))
      tags = optional(map(string))
    })))
    bastions = optional(map(object({
      name                = string
      resource_group_key = string
      vnet_key           = string
      subnet_key         = string
      public_ip_name     = string
      tags               = optional(map(string))
    })))
  })
  default = null
}

# Monitoring Configuration
variable "monitoring_configuration" {
  description = "Configuration for monitoring resources including log analytics workspaces and alerts"
  type = object({
    log_analytics = optional(map(object({
      name                = string
      resource_group_key = string
      retention_in_days   = optional(number)
      tags                = optional(map(string))
    })))
    alerts = optional(map(object({
      name                = string
      resource_group_key = string
      scopes             = list(string)
      description        = string
      severity          = number
      frequency         = string
      window_size       = string
      criteria = object({
        metric_namespace = string
        metric_name     = string
        aggregation     = string
        operator        = string
        threshold       = number
      })
      action = optional(object({
        action_group_id = string
        webhook        = optional(string)
      }))
      tags = optional(map(string))
    })))
  })
  default = null
}

# Compute Configuration
variable "compute_configuration" {
  description = "Configuration for compute resources including virtual machines"
  type = object({
    vms = optional(map(object({
      name                = string
      resource_group_key = string
      location           = optional(string)
      size               = string
      admin_username     = string
      admin_ssh_key      = string
      os_disk = object({
        name                 = optional(string)
        caching             = string
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
        name      = optional(string)
        subnet_key = string
        ip_configuration = object({
          name                          = optional(string)
          private_ip_address_allocation = string
          private_ip_address           = optional(string)
          public_ip_address = optional(object({
            name              = string
            allocation_method = string
            sku              = string
            tags             = optional(map(string))
          }))
        })
      })
      tags = optional(map(string))
    })))
  })
  default = null
}

# Storage Configuration
variable "storage_configuration" {
  description = "Configuration for storage resources including storage accounts, containers, and file shares"
  type = object({
    storage_accounts = optional(map(object({
      name                     = string
      resource_group_key      = string
      account_tier            = string
      account_replication_type = string
      account_kind           = string
      containers = optional(map(object({
        name                  = string
        container_access_type = string
      })))
      file_shares = optional(map(object({
        name        = string
        quota_in_gb = number
      })))
      tags = optional(map(string))
    })))
  })
  default = null
}

