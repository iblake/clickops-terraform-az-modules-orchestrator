# Azure Orchestrator Main Configuration

locals {
  # Resource group dependencies
  resource_groups_dependency = var.iam_configuration != null ? (
    var.iam_configuration.resource_groups != null ? {
      for key, rg in azurerm_resource_group.these : key => {
        id       = rg.id
        name     = rg.name
        location = rg.location
      }
    } : {}
  ) : {}

  # Network dependencies
  network_dependency = var.network_configuration != null ? (
    var.network_configuration.vnets != null ? {
      for key, vnet in azurerm_virtual_network.these : key => {
        id = vnet.id
        subnets = {
          for subnet_key, subnet in azurerm_subnet.these : subnet_key => {
            id = subnet.id
          } if split("-", subnet_key)[0] == key
        }
        network_security_groups = var.network_configuration.network_security_groups != null ? {
          for nsg_key, nsg in azurerm_network_security_group.these : nsg_key => {
            id = nsg.id
          }
        } : {}
      }
    } : {}
  ) : {}

  # Security dependencies
  security_dependency = var.security_configuration != null ? (
    var.security_configuration.key_vaults != null ? {
      for key, kv in azurerm_key_vault.these : key => {
        id = kv.id
      }
    } : {}
  ) : {}

  # Monitoring dependencies
  monitoring_dependency = var.monitoring_configuration != null ? (
    var.monitoring_configuration.log_analytics != null ? {
      for key, la in azurerm_log_analytics_workspace.these : key => {
        id = la.id
      }
    } : {}
  ) : {}

  # Compute configuration
  compute_config = var.compute_configuration
}

# Resource Groups
resource "azurerm_resource_group" "rg" {
  for_each = try(local.resource_groups_config.resource_groups, {})

  name     = each.value.name
  location = coalesce(each.value.location, try(local.resource_groups_config.default_location, null), "eastus")
  tags     = each.value.tags
}

# Virtual Networks
resource "azurerm_virtual_network" "vnet" {
  for_each = try(local.network_config.vnets, {})

  name                = each.value.name
  location            = azurerm_resource_group.rg[each.value.resource_group_key].location
  resource_group_name = azurerm_resource_group.rg[each.value.resource_group_key].name
  address_space       = each.value.address_space
}

# Subnets
resource "azurerm_subnet" "subnet" {
  for_each = local.flattened_subnets

  name                 = each.value.name
  resource_group_name  = azurerm_resource_group.rg[each.value.resource_group_key].name
  virtual_network_name = azurerm_virtual_network.vnet[each.value.vnet_key].name
  address_prefixes     = each.value.address_prefixes
}

# Network Security Groups
resource "azurerm_network_security_group" "nsg" {
  for_each = {
    for subnet_key, subnet in local.flattened_subnets :
    subnet_key => subnet
    if try(subnet.security_rules, null) != null
  }

  name                = "${each.value.name}-nsg"
  location            = azurerm_resource_group.rg[each.value.resource_group_key].location
  resource_group_name = azurerm_resource_group.rg[each.value.resource_group_key].name

  dynamic "security_rule" {
    for_each = each.value.security_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range         = security_rule.value.source_port_range
      destination_port_range    = security_rule.value.destination_port_range
      source_address_prefix     = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}

# NSG Association
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  for_each = {
    for subnet_key, subnet in local.flattened_subnets :
    subnet_key => subnet
    if try(subnet.security_rules, null) != null
  }

  subnet_id                 = azurerm_subnet.subnet[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}

# Compute Module
module "compute" {
  source = "./modules/compute"
  count  = local.compute_config != null ? 1 : 0

  configuration = {
    vms = {
      for k, v in try(local.compute_config.vms, {}) : k => {
        name                = v.name
        resource_group_id   = v.resource_group_key
        subnet_id          = "${v.resource_group_key}-${v.network_interface.subnet_key}"
        size               = v.size
        admin_username     = v.admin_username
        admin_ssh_key      = v.admin_ssh_key
        os_disk            = v.os_disk
        source_image_reference = v.source_image_reference
        public_ip         = v.network_interface.ip_configuration.public_ip_address != null
      }
    }
  }

  resource_group_ids = {
    for k, v in azurerm_resource_group.these : k => v.name
  }

  subnet_ids = {
    for k, v in azurerm_subnet.these : k => v.id
  }
}

# Security Resources (if configured)
module "security" {
  source = "./modules/security"
  count  = var.security_configuration != null ? 1 : 0

  configuration = var.security_configuration
  resource_group_ids = {
    for k, v in azurerm_resource_group.rg : k => v.name
  }
  subnet_ids = {
    for k, v in azurerm_subnet.subnet : k => v.id
  }
}

# Monitoring Resources (if configured)
module "monitoring" {
  source = "./modules/monitoring"
  count  = var.monitoring_configuration != null ? 1 : 0

  configuration = var.monitoring_configuration
  resource_group_ids = {
    for k, v in azurerm_resource_group.rg : k => v.name
  }
}

# IAM Resources
resource "azurerm_resource_group" "these" {
  for_each = var.iam_configuration != null ? (
    var.iam_configuration.resource_groups != null ? var.iam_configuration.resource_groups : {}
  ) : {}

  name     = each.value.name
  location = coalesce(each.value.location, local.default_location)
  tags     = each.value.tags
}

resource "azurerm_role_definition" "these" {
  for_each = var.iam_configuration != null ? (
    var.iam_configuration.roles != null ? var.iam_configuration.roles : {}
  ) : {}

  name        = each.value.name
  description = each.value.description
  scope       = "/subscriptions/${local.subscription_id}"

  permissions {
    actions          = each.value.permissions[0].actions
    not_actions      = each.value.permissions[0].not_actions
    data_actions     = each.value.permissions[0].data_actions
    not_data_actions = each.value.permissions[0].not_data_actions
  }

  assignable_scopes = [
    "/subscriptions/${local.subscription_id}"
  ]
}

resource "azurerm_role_assignment" "these" {
  for_each = var.iam_configuration != null ? (
    var.iam_configuration.role_assignments != null ? var.iam_configuration.role_assignments : {}
  ) : {}

  principal_id         = each.value.principal_id
  role_definition_name = each.value.role_name
  scope               = each.value.scope
}

# Network Resources
resource "azurerm_virtual_network" "these" {
  for_each = var.network_configuration != null ? (
    var.network_configuration.vnets != null ? var.network_configuration.vnets : {}
  ) : {}

  name                = each.value.name
  resource_group_name = local.resource_groups_dependency[each.value.resource_group_key].name
  location            = local.resource_groups_dependency[each.value.resource_group_key].location
  address_space       = each.value.address_space
  dns_servers         = each.value.dns_servers
  tags                = each.value.tags

  depends_on = [azurerm_resource_group.these]
}

resource "azurerm_subnet" "these" {
  for_each = var.network_configuration != null ? (
    var.network_configuration.vnets != null ? merge([
      for vnet_key, vnet in var.network_configuration.vnets :
      {
        for subnet_key, subnet in coalesce(vnet.subnets, {}) :
        "${vnet_key}-${subnet_key}" => merge(subnet, {
          vnet_key = vnet_key
          vnet_name = vnet.name
          resource_group_key = vnet.resource_group_key
        })
      }
    ]...) : {}
  ) : {}

  name                 = each.value.name
  resource_group_name  = local.resource_groups_dependency[each.value.resource_group_key].name
  virtual_network_name = each.value.vnet_name
  address_prefixes     = each.value.address_prefixes

  dynamic "delegation" {
    for_each = each.value.delegation != null ? each.value.delegation : {}
    content {
      name = delegation.key
      service_delegation {
        name    = delegation.value.name
        actions = delegation.value.actions
      }
    }
  }

  depends_on = [azurerm_virtual_network.these]
}

resource "azurerm_network_security_group" "these" {
  for_each = var.network_configuration != null ? (
    var.network_configuration.network_security_groups != null ? var.network_configuration.network_security_groups : {}
  ) : {}

  name                = each.value.name
  resource_group_name = local.resource_groups_dependency[each.value.resource_group_key].name
  location            = local.resource_groups_dependency[each.value.resource_group_key].location
  tags                = each.value.tags

  dynamic "security_rule" {
    for_each = coalesce(each.value.rules, [])
    content {
      name                         = security_rule.value.name
      priority                     = security_rule.value.priority
      direction                    = security_rule.value.direction
      access                       = security_rule.value.access
      protocol                     = security_rule.value.protocol
      source_port_range           = security_rule.value.source_port_range
      destination_port_range      = security_rule.value.destination_port_range
      source_address_prefix       = security_rule.value.source_address_prefix
      destination_address_prefix  = security_rule.value.destination_address_prefix
    }
  }

  depends_on = [azurerm_resource_group.these]
}

# Security Resources
resource "azurerm_key_vault" "these" {
  for_each = var.security_configuration != null ? (
    var.security_configuration.key_vaults != null ? var.security_configuration.key_vaults : {}
  ) : {}

  name                = each.value.name
  resource_group_name = local.resource_groups_dependency[each.value.resource_group_key].name
  location            = local.resource_groups_dependency[each.value.resource_group_key].location
  tenant_id           = each.value.tenant_id
  sku_name            = each.value.sku_name
  tags                = each.value.tags

  dynamic "access_policy" {
    for_each = coalesce(each.value.access_policies, [])
    content {
      tenant_id = access_policy.value.tenant_id
      object_id = access_policy.value.object_id

      key_permissions         = access_policy.value.key_permissions
      secret_permissions      = access_policy.value.secret_permissions
      certificate_permissions = access_policy.value.certificate_permissions
    }
  }

  depends_on = [azurerm_resource_group.these]
}

resource "azurerm_bastion_host" "these" {
  for_each = var.security_configuration != null ? (
    var.security_configuration.bastions != null ? var.security_configuration.bastions : {}
  ) : {}

  name                = each.value.name
  resource_group_name = local.resource_groups_dependency[each.value.resource_group_key].name
  location            = local.resource_groups_dependency[each.value.resource_group_key].location
  
  ip_configuration {
    name                 = "configuration"
    subnet_id            = local.network_dependency[each.value.vnet_key].subnets[each.value.subnet_key].id
    public_ip_address_id = azurerm_public_ip.bastion[each.key].id
  }

  tags = each.value.tags

  depends_on = [
    azurerm_resource_group.these,
    azurerm_virtual_network.these,
    azurerm_subnet.these,
    azurerm_public_ip.bastion
  ]
}

resource "azurerm_public_ip" "bastion" {
  for_each = var.security_configuration != null ? (
    var.security_configuration.bastions != null ? var.security_configuration.bastions : {}
  ) : {}

  name                = each.value.public_ip_name
  resource_group_name = local.resource_groups_dependency[each.value.resource_group_key].name
  location            = local.resource_groups_dependency[each.value.resource_group_key].location
  allocation_method   = "Static"
  sku                = "Standard"
  tags               = each.value.tags

  depends_on = [azurerm_resource_group.these]
}

# Monitoring Resources
resource "azurerm_log_analytics_workspace" "these" {
  for_each = var.monitoring_configuration != null ? (
    var.monitoring_configuration.log_analytics != null ? var.monitoring_configuration.log_analytics : {}
  ) : {}

  name                = each.value.name
  resource_group_name = local.resource_groups_dependency[each.value.resource_group_key].name
  location            = local.resource_groups_dependency[each.value.resource_group_key].location
  retention_in_days   = each.value.retention_in_days
  tags                = each.value.tags

  depends_on = [azurerm_resource_group.these]
}

resource "azurerm_monitor_metric_alert" "these" {
  for_each = var.monitoring_configuration != null ? (
    var.monitoring_configuration.alerts != null ? var.monitoring_configuration.alerts : {}
  ) : {}

  name                = each.value.name
  resource_group_name = local.resource_groups_dependency[each.value.resource_group_key].name
  scopes              = each.value.scopes
  description         = each.value.description
  severity            = each.value.severity
  frequency           = each.value.frequency
  window_size         = each.value.window_size

  criteria {
    metric_namespace = each.value.criteria.metric_namespace
    metric_name      = each.value.criteria.metric_name
    aggregation      = each.value.criteria.aggregation
    operator         = each.value.criteria.operator
    threshold        = each.value.criteria.threshold
  }

  dynamic "action" {
    for_each = each.value.action != null ? [each.value.action] : []
    content {
      action_group_id = action.value.action_group_id
      webhook_properties = action.value.webhook != null ? {
        url = action.value.webhook
      } : null
    }
  }

  tags = each.value.tags

  depends_on = [azurerm_resource_group.these]
}

# Compute Resources
resource "azurerm_network_interface" "these" {
  for_each = var.compute_configuration != null ? (
    var.compute_configuration.vms != null ? var.compute_configuration.vms : {}
  ) : {}

  name                = coalesce(each.value.network_interface.name, "${each.value.name}-nic")
  resource_group_name = local.resource_groups_dependency[each.value.resource_group_key].name
  location            = coalesce(each.value.location, local.resource_groups_dependency[each.value.resource_group_key].location)

  ip_configuration {
    name                          = coalesce(each.value.network_interface.ip_configuration.name, "internal")
    subnet_id                     = local.network_dependency[each.value.network_interface.subnet_key].id
    private_ip_address_allocation = each.value.network_interface.ip_configuration.private_ip_address_allocation
    private_ip_address           = each.value.network_interface.ip_configuration.private_ip_address
    public_ip_address_id         = each.value.network_interface.ip_configuration.public_ip_address != null ? azurerm_public_ip.vm[each.key].id : null
  }

  tags = each.value.tags

  depends_on = [
    azurerm_resource_group.these,
    azurerm_virtual_network.these,
    azurerm_subnet.these,
    azurerm_public_ip.vm
  ]
}

resource "azurerm_public_ip" "vm" {
  for_each = var.compute_configuration != null ? (
    var.compute_configuration.vms != null ? {
      for key, vm in var.compute_configuration.vms :
      key => vm if vm.network_interface.ip_configuration.public_ip_address != null
    } : {}
  ) : {}

  name                = each.value.network_interface.ip_configuration.public_ip_address.name
  resource_group_name = local.resource_groups_dependency[each.value.resource_group_key].name
  location            = coalesce(each.value.location, local.resource_groups_dependency[each.value.resource_group_key].location)
  allocation_method   = each.value.network_interface.ip_configuration.public_ip_address.allocation_method
  sku                = each.value.network_interface.ip_configuration.public_ip_address.sku
  tags               = each.value.network_interface.ip_configuration.public_ip_address.tags

  depends_on = [azurerm_resource_group.these]
}

resource "azurerm_linux_virtual_machine" "these" {
  for_each = var.compute_configuration != null ? (
    var.compute_configuration.vms != null ? var.compute_configuration.vms : {}
  ) : {}

  name                = each.value.name
  resource_group_name = local.resource_groups_dependency[each.value.resource_group_key].name
  location            = coalesce(each.value.location, local.resource_groups_dependency[each.value.resource_group_key].location)
  size                = each.value.size
  admin_username      = each.value.admin_username
  
  network_interface_ids = [
    azurerm_network_interface.these[each.key].id
  ]

  admin_ssh_key {
    username   = each.value.admin_username
    public_key = each.value.admin_ssh_key
  }

  os_disk {
    name                 = coalesce(each.value.os_disk.name, "${each.value.name}-osdisk")
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

  tags = each.value.tags

  depends_on = [
    azurerm_resource_group.these,
    azurerm_network_interface.these
  ]
}

# Storage Resources
resource "azurerm_storage_account" "these" {
  for_each = var.storage_configuration != null ? (
    var.storage_configuration.storage_accounts != null ? var.storage_configuration.storage_accounts : {}
  ) : {}

  name                     = each.value.name
  resource_group_name      = local.resource_groups_dependency[each.value.resource_group_key].name
  location                 = local.resource_groups_dependency[each.value.resource_group_key].location
  account_tier             = each.value.account_tier
  account_replication_type = each.value.account_replication_type
  account_kind            = each.value.account_kind
  tags                    = each.value.tags

  depends_on = [azurerm_resource_group.these]
}

resource "azurerm_storage_container" "these" {
  for_each = var.storage_configuration != null ? (
    var.storage_configuration.storage_accounts != null ? merge([
      for sa_key, sa in var.storage_configuration.storage_accounts :
      {
        for container_key, container in coalesce(sa.containers, {}) :
        "${sa_key}-${container_key}" => merge(container, {
          storage_account_key = sa_key
        })
      }
    ]...) : {}
  ) : {}

  name                  = each.value.name
  storage_account_name  = azurerm_storage_account.these[each.value.storage_account_key].name
  container_access_type = each.value.container_access_type

  depends_on = [azurerm_storage_account.these]
}

resource "azurerm_storage_share" "these" {
  for_each = var.storage_configuration != null ? (
    var.storage_configuration.storage_accounts != null ? merge([
      for sa_key, sa in var.storage_configuration.storage_accounts :
      {
        for share_key, share in coalesce(sa.file_shares, {}) :
        "${sa_key}-${share_key}" => merge(share, {
          storage_account_key = sa_key
        })
      }
    ]...) : {}
  ) : {}

  name                 = each.value.name
  storage_account_name = azurerm_storage_account.these[each.value.storage_account_key].name
  quota                = each.value.quota_in_gb

  depends_on = [azurerm_storage_account.these]
}
