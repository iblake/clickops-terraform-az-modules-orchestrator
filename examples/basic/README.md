# Basic Azure Infrastructure Example

This example demonstrates how to use the Azure Terraform Orchestrator to create a basic infrastructure setup with networking, storage, and compute resources using a modular approach.

## Architecture

This example creates:
- **Resource Groups**: Centralized resource management (IAM module)
- **Virtual Network**: With subnets for different tiers (Networking module)
- **Virtual Machine**: Linux VM with network interface (Compute module)

## Prerequisites

1. Azure CLI installed and configured
2. Terraform >= 1.0
3. Azure subscription with appropriate permissions

## Configuration Files

This example uses a modular approach with separate configuration files for each module:

### IAM Configuration (`iam.tfvars.json`)
```json
{
  "iam_configuration": {
    "resource_groups": {
      "test-rg": {
        "name": "test-rg",
        "location": "eastus",
        "tags": {
          "environment": "test"
        }
      }
    }
  }
}
```

### Networking Configuration (`networking.tfvars.json`)
```json
{
  "network_configuration": {
    "vnets": {
      "test-vnet": {
        "name": "test-vnet",
        "resource_group_key": "test-rg",
        "address_space": ["10.0.0.0/16"],
        "subnets": {
          "test-subnet": {
            "name": "test-subnet",
            "address_prefixes": ["10.0.1.0/24"]
          }
        }
      }
    }
  }
}
```

### Compute Configuration (`compute.tfvars.json`)
```json
{
  "compute_configuration": {
    "vms": {
      "test-vm": {
        "name": "test-vm",
        "resource_group_key": "test-rg",
        "size": "Standard_B1s",
        "admin_username": "azureuser",
        "admin_ssh_key": "ssh-rsa YOUR_PUBLIC_KEY_HERE",
        "network_interface": {
          "subnet_key": "test-subnet",
          "ip_configuration": {
            "name": "internal",
            "private_ip_address_allocation": "Dynamic"
          }
        },
        "os_disk": {
          "name": "test-vm-osdisk",
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

## Usage

1. **Update the configuration files**:
   - Replace `YOUR_PUBLIC_KEY_HERE` in `compute.tfvars.json` with your actual SSH public key
   - Modify resource names and locations as needed
   - Update the `resource_group_key` references to match your resource group names

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Plan the deployment**:
   ```bash
   terraform plan -var-file="iam.tfvars.json" -var-file="networking.tfvars.json" -var-file="compute.tfvars.json"
   ```

4. **Apply the configuration**:
   ```bash
   terraform apply -var-file="iam.tfvars.json" -var-file="networking.tfvars.json" -var-file="compute.tfvars.json"
   ```

5. **Access your resources**:
   - VM: Use the private IP address with SSH (through VPN or bastion host)
   - Resource Groups: Manage through Azure Portal

## Modular Approach Benefits

This example demonstrates the benefits of using separate configuration files:

### Flexibility
- **Selective Deployment**: Deploy only the modules you need
- **Environment Management**: Use different configurations for dev, staging, and production
- **Team Collaboration**: Different teams can manage their own configuration files

### Maintainability
- **Clear Separation**: Each module has its own configuration file
- **Easier Updates**: Modify specific modules without affecting others
- **Version Control**: Track changes per module

### Reusability
- **Module Reuse**: Use the same module configuration across different projects
- **Template Creation**: Create templates for common configurations
- **Standardization**: Enforce consistent configurations across environments

## Module Integration

This example demonstrates how the orchestrator modules work together:

### IAM Module
- Creates and manages resource groups
- Handles role assignments and permissions
- Provides centralized resource management

### Networking Module
- Creates the virtual network and subnets
- Configures network security groups
- Establishes the network foundation

### Compute Module
- Creates virtual machines
- Configures network interfaces
- Manages OS disks and image references

## Outputs

After successful deployment, you can access:

- **Resource Groups**: View in Azure Portal
- **Virtual Network**: Manage subnets and network settings
- **VM Connection**: SSH to the private IP address (requires VPN or bastion)

## Cleanup

To destroy the infrastructure:

```bash
terraform destroy -var-file="iam.tfvars.json" -var-file="networking.tfvars.json" -var-file="compute.tfvars.json"
```

## Customization

You can customize this example by:

1. **Adding more resource groups**: Extend the IAM configuration
2. **Creating additional subnets**: Extend the networking configuration
3. **Adding more VMs**: Extend the compute configuration
4. **Including other modules**: Add storage, security, or monitoring configurations

## Advanced Usage

### Partial Deployments
Deploy only specific modules:

```bash
# Deploy only IAM and networking
terraform apply -var-file="iam.tfvars.json" -var-file="networking.tfvars.json"

# Deploy only compute (requires networking to exist)
terraform apply -var-file="compute.tfvars.json"
```

### Environment-Specific Configurations
Create environment-specific files:

```bash
# Development environment
terraform apply -var-file="iam-dev.tfvars.json" -var-file="networking-dev.tfvars.json" -var-file="compute-dev.tfvars.json"

# Production environment
terraform apply -var-file="iam-prod.tfvars.json" -var-file="networking-prod.tfvars.json" -var-file="compute-prod.tfvars.json"
```

## Troubleshooting

### Common Issues

1. **Authentication Errors**: Ensure Azure CLI is properly configured
2. **Resource Name Conflicts**: Azure resource names must be globally unique
3. **Permission Errors**: Verify your Azure account has necessary permissions
4. **Module Dependencies**: Ensure modules are deployed in the correct order

### Debugging

1. Use `terraform plan` to preview changes
2. Check Azure Portal for resource status
3. Review Terraform logs for detailed error messages
4. Validate configuration syntax with `terraform validate`

## Next Steps

After successfully deploying this basic example:

1. **Explore Advanced Features**: Try adding storage and security modules
2. **Customize Configuration**: Modify the JSON files to match your requirements
3. **Add Monitoring**: Include monitoring module configurations
4. **Implement Security**: Add security module with key vaults and NSGs
5. **Scale Resources**: Add more VMs, storage, or networking components
