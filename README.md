# Azure Resource Orchestrator

This module provides a flexible and modular approach to managing Azure resources. It follows a similar structure to the OCI Landing Zones Orchestrator, allowing you to manage multiple resource types through a single, consistent configuration interface.

## Prerequisites

1. Azure Subscription
2. Azure CLI installed and configured
3. Terraform >= 1.0.0 (updated from 1.3.0)
4. Azure Service Principal with required permissions

## Authentication and Sensitive Parameters

This orchestrator follows the exact same pattern as the OCI orchestrator for managing credentials and sensitive parameters:

1. **Credentials Management**:
   - Use `credentials.auto.tfvars.json` for authentication (same as OCI orchestrator)
   - Never commit this file to version control (automatically excluded via .gitignore)
   - Example file provided as `credentials.auto.tfvars.json.example`

2. **Configuration Files**:
   - Main configuration in `terraform.tfvars.json` (same as OCI orchestrator)
   - Separates configuration from sensitive data
   - Clear separation between infrastructure definition and credentials

3. **Sensitive Parameters**:
   - All sensitive variables are marked with `sensitive = true`
   - Follows the same security practices as OCI orchestrator
   - Credentials are never exposed in logs or outputs

## Features

- **IAM Management**: Resource groups, roles, and role assignments
- **Network Management**: Virtual networks, subnets, and network security groups
- **Security Management**: Key vaults and bastion hosts
- **Monitoring**: Log analytics workspaces and metric alerts
- **Compute**: Linux virtual machines with network interfaces
- **Storage**: Storage accounts, containers, and file shares

## Module Structure

```
terraform-azure-orchestrator/
├── main.tf           # Main module configuration
├── variables.tf      # Input variable definitions
├── outputs.tf        # Output definitions
├── locals.tf         # Local variable definitions
├── versions.tf       # Version constraints
├── providers.tf      # Provider configuration
├── modules/
│   ├── compute/      # VM and related resources
│   ├── iam/          # Identity and access management
│   └── monitoring/   # Logging and alerting
├── examples/
│   └── basic/        # Basic usage example
└── README.md
```

## Configuration Structure

The module accepts the following configuration blocks:

### IAM Configuration

```hcl
iam_configuration = {
  resource_groups = {
    key = {
      name     = string
      location = optional(string)
      tags     = optional(map(string))
    }
  }
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
}
```

### Network Configuration

```hcl
network_configuration = {
  vnets = {
    key = {
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
    }
  }
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
}
```

### Security Configuration

```hcl
security_configuration = {
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
}
```

### Monitoring Configuration

```hcl
monitoring_configuration = {
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
}
```

### Compute Configuration

```hcl
compute_configuration = {
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
}
```

### Storage Configuration

```hcl
storage_configuration = {
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
}
```

## Best Practices

1. **Resource Naming**:
   - Use consistent naming conventions
   - Include environment/purpose in names
   - Keep names unique within resource types

2. **Resource Groups**:
   - Group related resources together
   - Use separate groups for different environments
   - Consider lifecycle differences

3. **Networking**:
   - Plan address spaces carefully
   - Use network security groups
   - Enable service endpoints where needed

4. **Security**:
   - Use managed identities where possible
   - Rotate credentials regularly
   - Implement least privilege access

5. **Monitoring**:
   - Enable diagnostic settings
   - Set up meaningful alerts
   - Configure appropriate retention periods

## Cost Optimization

1. **Free Tier Resources**:
   - Standard_B1s VM (12 months free)
   - Standard_LRS storage (12 months free)
   - Basic public IPs
   - Free networking features

2. **Cost Reduction Strategies**:
   - Use auto-shutdown for non-production VMs
   - Clean up unused resources
   - Right-size VM instances
   - Use reserved instances for production

## Common Issues and Solutions

1. **Authentication**:
   - Ensure environment variables are set
   - Check Service Principal permissions
   - Verify subscription access

2. **Network**:
   - Address space conflicts
   - Subnet delegation requirements
   - Service endpoint availability

3. **Resource Provisioning**:
   - Region resource availability
   - Quota limitations
   - Name uniqueness requirements

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This module is licensed under the MIT License. See the LICENSE file for details. 