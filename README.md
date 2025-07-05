# Azure Resource Orchestrator

This module provides a flexible and modular approach to managing Azure resources. It follows a similar structure to the OCI Landing Zones Orchestrator, allowing you to manage multiple resource types through a single, consistent configuration interface.

## Features

- **IAM Management**: Resource groups, roles, and role assignments
- **Network Management**: Virtual networks, subnets, and network security groups
- **Security Management**: Key vaults and bastion hosts
- **Monitoring**: Log analytics workspaces and metric alerts
- **Compute**: Linux virtual machines with network interfaces
- **Storage**: Storage accounts, containers, and file shares

## Prerequisites

1. Azure Subscription
2. Azure CLI installed and configured
3. Terraform >= 1.3.0
4. Azure Service Principal with required permissions
5. Basic understanding of Azure resource management

## Quick Start

1. Configure Azure credentials as environment variables:
```bash
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
```

2. Create a basic configuration file (`terraform.tfvars.json`):
```json
{
  "iam_configuration": {
    "resource_groups": {
      "example-rg": {
        "name": "example-rg",
        "location": "eastus",
        "tags": {
          "environment": "dev"
        }
      }
    }
  }
}
```

3. Use the module in your Terraform configuration:
```hcl
module "azure_orchestrator" {
  source = "path/to/terraform-azure-orchestrator"

  # Configuration is loaded from terraform.tfvars.json
}
```

## Module Structure

```
terraform-azure-orchestrator/
├── main.tf           # Main module configuration
├── variables.tf      # Input variable definitions
├── outputs.tf        # Output definitions
├── locals.tf         # Local variable definitions
├── modules/
│   ├── compute/      # VM and related resources
│   ├── iam/          # Identity and access management
│   ├── monitoring/   # Logging and alerting
│   ├── network/      # Network resources
│   ├── security/     # Security resources
│   └── storage/      # Storage resources
├── examples/
│   ├── basic/        # Basic usage example
│   ├── complete/     # Complete usage example
│   └── free-tier/    # Free tier compatible example
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
      location = string
      tags     = map(string)
    }
  }
  roles = {
    key = {
      name        = string
      description = string
      permissions = list(object({
        actions          = list(string)
        not_actions      = list(string)
        data_actions     = list(string)
        not_data_actions = list(string)
      }))
    }
  }
  role_assignments = {
    key = {
      role_name     = string
      principal_id  = string
      scope         = string
    }
  }
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
      dns_servers        = list(string)
      subnets = {
        key = {
          name              = string
          address_prefixes  = list(string)
          security_group    = string
          service_endpoints = list(string)
        }
      }
    }
  }
  network_security_groups = {
    key = {
      name               = string
      resource_group_key = string
      rules = list(object({
        name                       = string
        priority                   = number
        direction                  = string
        access                     = string
        protocol                   = string
        source_port_range         = string
        destination_port_range    = string
        source_address_prefix     = string
        destination_address_prefix = string
      }))
    }
  }
}
```

### Security Configuration

```hcl
security_configuration = {
  key_vaults = {
    key = {
      name                = string
      resource_group_key = string
      sku_name           = string
      tenant_id          = string
      access_policies    = list(object({
        tenant_id = string
        object_id = string
        key_permissions = list(string)
        secret_permissions = list(string)
        certificate_permissions = list(string)
      }))
    }
  }
  bastions = {
    key = {
      name                = string
      resource_group_key = string
      vnet_key           = string
      subnet_key         = string
      public_ip_name     = string
    }
  }
}
```

### Monitoring Configuration

```hcl
monitoring_configuration = {
  log_analytics = {
    key = {
      name                = string
      resource_group_key = string
      retention_in_days   = number
    }
  }
  alerts = {
    key = {
      name                = string
      resource_group_key = string
      scopes             = list(string)
      description        = string
      severity           = number
      frequency         = string
      window_size       = string
      criteria          = object({
        metric_namespace = string
        metric_name     = string
        aggregation     = string
        operator        = string
        threshold       = number
      })
    }
  }
}
```

### Compute Configuration

```hcl
compute_configuration = {
  vms = {
    key = {
      name                = string
      resource_group_key = string
      size               = string
      admin_username     = string
      admin_ssh_key      = string
      network_interface = object({
        subnet_key      = string
        ip_configuration = object({
          name                          = string
          private_ip_address_allocation = string
        })
      })
      os_disk = object({
        name                 = string
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
    }
  }
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