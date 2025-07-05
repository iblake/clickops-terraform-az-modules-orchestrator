locals {
  # Default location
  default_location = "eastus"
  
  # Subscription ID from data source
  subscription_id = data.azurerm_subscription.current.subscription_id
  tenant_id      = data.azurerm_client_config.current.tenant_id

  # Flattened subnets for easier iteration
  flattened_subnets = var.network_configuration != null ? (
    var.network_configuration.vnets != null ? merge([
      for vnet_key, vnet in var.network_configuration.vnets : {
        for subnet_key, subnet in try(vnet.subnets, {}) : "${vnet_key}-${subnet_key}" => merge(subnet, {
          vnet_key = vnet_key
          resource_group_key = vnet.resource_group_key
        })
      }
    ]...) : {}
  ) : {}

  # Map to get vnet key for a given subnet key
  get_vnet_key_for_subnet = var.network_configuration != null ? (
    var.network_configuration.vnets != null ? merge([
      for vnet_key, vnet in var.network_configuration.vnets : {
        for subnet_key, subnet in try(vnet.subnets, {}) : subnet_key => vnet_key
      }
    ]...) : {}
  ) : {}

  # Flattened containers for easier iteration
  flattened_containers = var.storage_configuration != null ? (
    var.storage_configuration.storage_accounts != null ? merge([
      for sa_key, sa in var.storage_configuration.storage_accounts : {
        for container_key, container in try(sa.containers, {}) : "${sa_key}-${container_key}" => merge(container, {
          storage_account_key = sa_key
        })
      }
    ]...) : {}
  ) : {}

  # Flattened file shares for easier iteration
  flattened_file_shares = var.storage_configuration != null ? (
    var.storage_configuration.storage_accounts != null ? merge([
      for sa_key, sa in var.storage_configuration.storage_accounts : {
        for share_key, share in try(sa.file_shares, {}) : "${sa_key}-${share_key}" => merge(share, {
          storage_account_key = sa_key
        })
      }
    ]...) : {}
  ) : {}

  # Dependencies for modules
  resource_groups_dependency = var.iam_configuration != null ? (
    var.iam_configuration.resource_groups != null ? {
      for key, rg in azurerm_resource_group.these : key => {
        id       = rg.id
        name     = rg.name
        location = rg.location
      }
    } : {}
  ) : {}

  network_dependency = var.network_configuration != null ? (
    var.network_configuration.vnets != null ? {
      for key, vnet in module.azure_lz_network[0].virtual_networks : key => {
        id = vnet.id
        subnets = {
          for subnet_key, subnet in module.azure_lz_network[0].subnets : subnet_key => {
            id = subnet.id
          } if subnet.virtual_network == vnet.name
        }
        network_security_groups = var.network_configuration.network_security_groups != null ? {
          for nsg_key, nsg in module.azure_lz_network[0].network_security_groups : nsg_key => {
            id = nsg.id
          }
        } : {}
      }
    } : {}
  ) : {}

  security_dependency = var.security_configuration != null ? (
    var.security_configuration.key_vaults != null ? {
      for key, kv in module.azure_lz_security[0].key_vaults : key => {
        id = kv.id
      }
    } : {}
  ) : {}

  monitoring_dependency = var.monitoring_configuration != null ? (
    var.monitoring_configuration.log_analytics != null ? {
      for key, la in azurerm_log_analytics_workspace.these : key => {
        id = la.id
      }
    } : {}
  ) : {}
} 