# Module Development Guide for Azure Orchestrator

This guide explains in detail how to develop additional modules that are compatible with the Azure orchestrator. The design follows the same pattern as the OCI orchestrator to ensure consistency and seamless integration.

## Design Principles

### 1. Input Structure
Modules should receive their configuration through a structured object following this pattern:

```hcl
variable "configuration" {
  description = "Module's main configuration object"
  type = object({
    resource_type = map(object({
      # Resource-specific properties
    }))
  })
}
```

### 2. Resource References
Modules should receive ID maps to reference external resources:

```hcl
variable "resource_group_ids" {
  description = "Map of resource_group_key to ID"
  type = map(string)
}

variable "subnet_ids" {
  description = "Map of subnet_key to ID"
  type = map(string)
}
```

## Module Structure

```plaintext
modules/
└── your_module/
    ├── main.tf       # Main resources
    ├── variables.tf  # Variable definitions
    ├── outputs.tf    # Standardized outputs
    └── README.md     # Module-specific documentation
```

## Authentication and Sensitive Data

All modules should follow the same authentication pattern as the OCI orchestrator:

1. **Credentials**:
   - Use `credentials.auto.tfvars.json` for authentication
   - Never commit credential files to version control
   - Provide example files with `.example` extension

2. **Sensitive Variables**:
   - Mark sensitive outputs with `sensitive = true`
   - Use variables for all sensitive values
   - Follow the same security practices as OCI orchestrator

## Practical Example: Compute Module

Let's see a complete example of how to implement a compute module:

### 1. variables.tf
```hcl
variable "configuration" {
  description = "Virtual Machines configuration"
  type = object({
    vms = map(object({
      name                = string
      resource_group_key = string
      size               = string
      admin_username     = string
      admin_ssh_key      = string
      network_interface = object({
        subnet_key = string
        ip_configuration = object({
          name                          = string
          private_ip_address_allocation = string
        })
      })
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
    }))
  })
}

variable "resource_group_ids" {
  description = "Map of resource_group_key to ID"
  type = map(string)
}

variable "subnet_ids" {
  description = "Map of subnet_key to ID"
  type = map(string)
}
```

### 2. main.tf
```hcl
# Resource Groups data source
data "azurerm_resource_group" "rg" {
  for_each = toset([
    for vm in var.configuration.vms : vm.resource_group_key
  ])
  name = var.resource_group_ids[each.value]
}

# Network Interfaces
resource "azurerm_network_interface" "nic" {
  for_each = var.configuration.vms

  name                = "${each.value.name}-nic"
  location            = data.azurerm_resource_group.rg[each.value.resource_group_key].location
  resource_group_name = data.azurerm_resource_group.rg[each.value.resource_group_key].name

  ip_configuration {
    name                          = each.value.network_interface.ip_configuration.name
    subnet_id                     = var.subnet_ids[each.value.network_interface.subnet_key]
    private_ip_address_allocation = each.value.network_interface.ip_configuration.private_ip_address_allocation
  }
}

# Virtual Machines
resource "azurerm_linux_virtual_machine" "vm" {
  for_each = var.configuration.vms

  name                = each.value.name
  resource_group_name = data.azurerm_resource_group.rg[each.value.resource_group_key].name
  location            = data.azurerm_resource_group.rg[each.value.resource_group_key].location
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
    disk_size_gb        = each.value.os_disk.disk_size_gb
  }

  source_image_reference {
    publisher = each.value.source_image_reference.publisher
    offer     = each.value.source_image_reference.offer
    sku       = each.value.source_image_reference.sku
    version   = each.value.source_image_reference.version
  }
}
```

### 3. outputs.tf
```hcl
output "virtual_machines" {
  description = "Map of created virtual machines"
  value = {
    for k, v in azurerm_linux_virtual_machine.vm : k => {
      id                  = v.id
      name                = v.name
      resource_group_name = v.resource_group_name
      private_ip_address  = azurerm_network_interface.nic[k].private_ip_address
    }
  }
}
```

## Integration with the Orchestrator

### 1. Update Orchestrator's variables.tf
```hcl
variable "configuration" {
  type = object({
    # ... existing configuration ...
    compute = optional(object({
      vms = map(object({
        name                = string
        resource_group_key = string
        size               = string
        admin_username     = string
        admin_ssh_key      = string
        network_interface = object({
          subnet_key = string
          ip_configuration = object({
            name                          = string
            private_ip_address_allocation = string
          })
        })
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
      }))
    }))
  })
}
```

### 2. Update Orchestrator's main.tf
```hcl
module "compute" {
  source = "./modules/compute"
  count  = var.configuration.compute != null ? 1 : 0

  configuration = var.configuration.compute
  
  resource_group_ids = {
    for k, v in azurerm_resource_group.rg : k => v.name
  }
  
  subnet_ids = {
    for k, v in azurerm_subnet.subnet : k => v.id
  }
}
```

## Best Practices

1. **Dependency Management**
   - Use `resource_group_key` instead of direct names
   - Implement data sources for external resources
   - Use `depends_on` only when absolutely necessary

2. **Input Validation**
```hcl
variable "configuration" {
  # ... type definition ...

  validation {
    condition = alltrue([
      for k, v in var.configuration.vms :
      can(regex("^[a-zA-Z0-9-]{1,64}$", v.name))
    ])
    error_message = "VM names must be 1-64 characters long and contain only letters, numbers, and hyphens."
  }
}
```

3. **Optional Fields Handling**
   - Use `optional()` for non-required fields
   - Provide sensible defaults
   - Use `try()` for handling null fields

4. **Standardized Outputs**
   - Always return created resource IDs
   - Use consistent naming (e.g., `resource_ids`)
   - Mark sensitive data with `sensitive = true`

5. **Documentation**
   - README.md with usage examples
   - Document each variable and output
   - Include validations and constraints

## Example JSON Configuration

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