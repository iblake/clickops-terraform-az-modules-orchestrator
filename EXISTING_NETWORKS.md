# Using Existing Virtual Networks and Subnets

This guide explains how to use existing Azure Virtual Networks and Subnets with the Azure Resource Orchestrator.

## Overview

The Azure Resource Orchestrator supports referencing existing Virtual Networks and Subnets without creating new ones. This is useful when:

- You have existing network infrastructure that you want to keep
- You want to gradually migrate to Terraform-managed resources
- You need to integrate with networks managed by other teams
- You want to avoid network conflicts in shared environments

## Configuration

### Basic Syntax

To use an existing VNet or subnet, add the `use_existing: true` parameter to your configuration:

```json
{
  "network_configuration": {
    "vnets": {
      "my-existing-vnet": {
        "name": "existing-vnet-name",
        "resource_group_key": "my-rg",
        "use_existing": true
      }
    }
  }
}
```

### Required Parameters

When using `use_existing: true`, you only need to specify:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `name` | string | Yes | **Must match** the exact name of the existing VNet/subnet |
| `resource_group_key` | string | Yes | Key reference to the resource group where the VNet/subnet exists |
| `use_existing` | boolean | Yes | Must be set to `true` |

### Optional Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `tags` | map(string) | Tags to apply to the data source (for tracking purposes) |

## Examples

### Using Existing VNet Only

```json
{
  "network_configuration": {
    "vnets": {
      "existing-vnet": {
        "name": "my-existing-vnet",
        "resource_group_key": "my-rg",
        "use_existing": true
      }
    }
  }
}
```

### Using Existing VNet with New Subnets

```json
{
  "network_configuration": {
    "vnets": {
      "existing-vnet": {
        "name": "my-existing-vnet",
        "resource_group_key": "my-rg",
        "use_existing": true,
        "subnets": {
          "new-subnet": {
            "name": "new-subnet",
            "address_prefixes": ["10.0.2.0/24"]
          }
        }
      }
    }
  }
}
```

### Using Existing Subnet

```json
{
  "network_configuration": {
    "vnets": {
      "existing-vnet": {
        "name": "my-existing-vnet",
        "resource_group_key": "my-rg",
        "use_existing": true,
        "subnets": {
          "existing-subnet": {
            "name": "my-existing-subnet",
            "use_existing": true
          }
        }
      }
    }
  }
}
```

### Mixed Approach (Existing + New Resources)

```json
{
  "network_configuration": {
    "vnets": {
      "existing-vnet": {
        "name": "existing-vnet",
        "resource_group_key": "my-rg",
        "use_existing": true
      },
      "new-vnet": {
        "name": "new-vnet",
        "resource_group_key": "my-rg",
        "address_space": ["10.1.0.0/16"],
        "subnets": {
          "new-subnet": {
            "name": "new-subnet",
            "address_prefixes": ["10.1.1.0/24"]
          }
        }
      }
    }
  }
}
```

## Integration with Other Resources

### Compute Resources

When using existing VNets/subnets, you can reference them in your compute configuration:

```json
{
  "compute_configuration": {
    "vms": {
      "my-vm": {
        "name": "my-vm",
        "resource_group_key": "my-rg",
        "size": "Standard_B1s",
        "admin_username": "azureuser",
        "admin_ssh_key": "ssh-rsa YOUR_KEY",
        "network_interface": {
          "subnet_key": "existing-subnet",  // References existing subnet
          "ip_configuration": {
            "name": "internal",
            "private_ip_address_allocation": "Dynamic"
          }
        },
        "os_disk": {
          "caching": "ReadWrite",
          "storage_account_type": "Standard_LRS",
          "disk_size_gb": 30
        },
        "source_image_reference": {
          "publisher": "Canonical",
          "offer": "UbuntuServer",
          "sku": "18.04-LTS",
          "version": "latest"
        }
      }
    }
  }
}
```

### Security Resources

You can also use existing VNets with security resources like Network Security Groups:

```json
{
  "network_configuration": {
    "vnets": {
      "existing-vnet": {
        "name": "existing-vnet",
        "resource_group_key": "my-rg",
        "use_existing": true
      }
    },
    "network_security_groups": {
      "new-nsg": {
        "name": "new-nsg",
        "resource_group_key": "my-rg",
        "rules": [
          {
            "name": "allow-ssh",
            "priority": 100,
            "direction": "Inbound",
            "access": "Allow",
            "protocol": "Tcp",
            "source_port_range": "*",
            "destination_port_range": "22",
            "source_address_prefix": "*",
            "destination_address_prefix": "*"
          }
        ]
      }
    }
  }
}
```

## Best Practices

### 1. Verify Resource Names

Before using `use_existing: true`, verify that the VNet/subnet names exactly match existing resources:

```bash
# Check existing VNets
az network vnet list --resource-group my-rg --query "[].name" -o tsv

# Check existing subnets
az network vnet subnet list --resource-group my-rg --vnet-name existing-vnet --query "[].name" -o tsv
```

### 2. Use Descriptive Keys

Use descriptive keys in your configuration to make it clear which resources are existing:

```json
{
  "vnets": {
    "existing-production-vnet": {  // Clear key name
      "name": "prod-vnet-001",
      "resource_group_key": "prod-rg",
      "use_existing": true
    }
  }
}
```

### 3. Document Dependencies

Document any external dependencies in your configuration:

```json
{
  "vnets": {
    "existing-vnet": {
      "name": "shared-vnet",
      "resource_group_key": "shared-rg",
      "use_existing": true,
      "tags": {
        "managed-by": "terraform-orchestrator",
        "external-dependency": "true",
        "owner": "network-team"
      }
    }
  }
}
```

### 4. Gradual Migration

Use the mixed approach to gradually migrate to Terraform-managed resources:

1. Start with existing VNets/subnets
2. Create new resources alongside existing ones
3. Gradually replace existing resources with Terraform-managed ones

## Troubleshooting

### Common Errors

#### "Resource not found"
```
Error: creating/updating Virtual Network: network.VirtualNetworksClient#CreateOrUpdate: Failure sending request: StatusCode=404 -- Original Error: Code="ResourceNotFound" Message="The Resource 'Microsoft.Network/virtualNetworks/existing-vnet' under resource group 'my-rg' was not found."
```

**Solution**: Verify the VNet name and resource group name are correct.

#### "Resource already exists"
```
Error: creating/updating Virtual Network: network.VirtualNetworksClient#CreateOrUpdate: Failure sending request: StatusCode=409 -- Original Error: Code="VnetAlreadyExists" Message="Virtual network 'existing-vnet' already exists in resource group 'my-rg'."
```

**Solution**: Add `use_existing: true` to your VNet configuration.

### Validation

Use Terraform's validation to catch configuration errors early:

```bash
# Validate configuration
terraform validate

# Plan to see what resources will be created/referenced
terraform plan -var-file="configuration.tfvars.json"
```

## Complete Example

See [`examples/existing-networks.tfvars.json`](./examples/existing-networks.tfvars.json) for a complete example that demonstrates:

- Using existing VNets
- Creating new VNets alongside existing ones
- Deploying compute resources in existing networks
- Managing security groups with existing networks

## Migration Guide

If you're migrating from manually created VNets to Terraform-managed ones:

1. **Phase 1**: Use `use_existing: true` to reference current VNets
2. **Phase 2**: Create new VNets alongside existing ones
3. **Phase 3**: Migrate resources to new VNets
4. **Phase 4**: Remove `use_existing: true` and manage all VNets with Terraform

This approach ensures zero downtime and allows for gradual migration. 