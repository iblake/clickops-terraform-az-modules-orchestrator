# Azure Orchestrator Basic Example

This example demonstrates how to use the Azure Orchestrator module to create a basic infrastructure that includes:
- Resource Groups
- Virtual Network with subnet
- Linux Virtual Machine with networking

## Prerequisites

1. Azure Subscription
2. Azure CLI installed and configured
3. Terraform >= 1.3.0
4. Azure Service Principal with required permissions
5. SSH key pair for VM access

## Credential Configuration

Create a `credentials.auto.tfvars.json` file based on the provided example:

```json
{
  "subscription_id": "your-subscription-id",
  "tenant_id": "your-tenant-id",
  "client_id": "your-client-id",
  "client_secret": "your-client-secret"
}
```

To create a Service Principal and get these credentials:

```bash
# Login to Azure
az login

# Create Service Principal and get credentials
az ad sp create-for-rbac --name "terraform-sp" --role contributor
```

The command output will contain the required credentials:
- `appId` is your `client_id`
- `password` is your `client_secret`
- `tenant` is your `tenant_id`

To get your subscription ID:
```bash
az account show --query id -o tsv
```

## Usage

1. Configure credentials as described above
2. Initialize Terraform:
   ```bash
   terraform init
   ```
3. Review the plan:
   ```bash
   terraform plan
   ```
4. Apply changes:
   ```bash
   terraform apply
   ```

## Configuration Example

The module uses a JSON configuration file (`terraform.tfvars.json`) to define resources:

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
  },
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
  },
  "compute_configuration": {
    "vms": {
      "test-vm": {
        "name": "test-vm",
        "resource_group_key": "test-rg",
        "size": "Standard_B1s",
        "admin_username": "azureuser",
        "admin_ssh_key": "ssh-rsa YOUR_SSH_KEY",
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

## File Structure

- `credentials.auto.tfvars.json`: Azure authentication credentials
- `terraform.tfvars.json`: Resource configuration (resource groups, network, VMs)
- `main.tf`: Main Terraform configuration
- `outputs.tf`: Module outputs

## Module Structure

```
terraform-azure-orchestrator/
├── modules/
│   ├── compute/
│   │   ├── main.tf       # Resource creation logic
│   │   ├── variables.tf  # Input variables
│   │   └── outputs.tf    # Output definitions
│   └── monitoring/       # Future monitoring module
├── examples/
│   └── basic/           # This example
└── README.md
```

## Security Notes

1. NEVER commit real credentials to version control
2. Use `.gitignore` to exclude credential files
3. Consider using Azure Key Vault for secrets management in production
4. Rotate Service Principal credentials regularly
5. Use minimal required permissions for Service Principal

## Cost Considerations

1. Standard_B1s VM is Free Tier eligible for 12 months
2. Standard_LRS storage is Free Tier eligible
3. Virtual Network usage is free
4. Network Interface is free
5. Total cost after Free Tier: ~$9-10/month

## Cleanup

To remove all resources:
```bash
terraform destroy
```

## Common Issues and Solutions

1. **Authentication Errors**:
   - Ensure credentials are correct in credentials.auto.tfvars.json
   - Verify Service Principal has sufficient permissions
   - Check subscription is active and accessible

2. **Resource Group Location**:
   - Default is "eastus" for Free Tier compatibility
   - Can be changed in resource group configuration

3. **Network Configuration**:
   - VNet and Subnet are automatically created
   - Default VNet range is 10.0.0.0/16
   - Default Subnet range is 10.0.1.0/24

4. **VM Access**:
   - VM is created without public IP for security
   - Access through private IP within VNet
   - Use Azure Bastion or VPN for external access 