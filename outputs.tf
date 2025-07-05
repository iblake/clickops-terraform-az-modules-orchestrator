# Azure Orchestrator Outputs

# IAM Resources Output
output "iam_resources" {
  description = "Details of all IAM resources created"
  value = {
    resource_groups = var.iam_configuration != null ? (
      var.iam_configuration.resource_groups != null ? {
        for key, rg in azurerm_resource_group.these : key => {
          id       = rg.id
          name     = rg.name
          location = rg.location
        }
      } : {}
    ) : {}
    roles = var.iam_configuration != null ? (
      var.iam_configuration.roles != null ? {
        for key, role in azurerm_role_definition.these : key => {
          id          = role.role_definition_id
          name        = role.name
          description = role.description
        }
      } : {}
    ) : {}
    role_assignments = var.iam_configuration != null ? (
      var.iam_configuration.role_assignments != null ? {
        for key, assignment in azurerm_role_assignment.these : key => {
          id           = assignment.id
          principal_id = assignment.principal_id
          scope        = assignment.scope
        }
      } : {}
    ) : {}
  }
}

# Network Resources Output
output "network_resources" {
  description = "Details of all network resources created"
  value = {
    virtual_networks = var.network_configuration != null ? (
      var.network_configuration.vnets != null ? {
        for key, vnet in azurerm_virtual_network.these : key => {
          id            = vnet.id
          name          = vnet.name
          address_space = vnet.address_space
        }
      } : {}
    ) : {}
    subnets = var.network_configuration != null ? (
      var.network_configuration.vnets != null ? {
        for key, subnet in azurerm_subnet.these : key => {
          id               = subnet.id
          name             = subnet.name
          address_prefixes = subnet.address_prefixes
        }
      } : {}
    ) : {}
    network_security_groups = var.network_configuration != null ? (
      var.network_configuration.network_security_groups != null ? {
        for key, nsg in azurerm_network_security_group.these : key => {
          id   = nsg.id
          name = nsg.name
        }
      } : {}
    ) : {}
  }
}

# Security Resources Output
output "security_resources" {
  description = "Details of all security resources created"
  value = {
    key_vaults = var.security_configuration != null ? (
      var.security_configuration.key_vaults != null ? {
        for key, kv in azurerm_key_vault.these : key => {
          id        = kv.id
          name      = kv.name
          vault_uri = kv.vault_uri
        }
      } : {}
    ) : {}
    bastions = var.security_configuration != null ? (
      var.security_configuration.bastions != null ? {
        for key, bastion in azurerm_bastion_host.these : key => {
          id   = bastion.id
          name = bastion.name
          ip_configuration = {
            public_ip_address = azurerm_public_ip.bastion[key].ip_address
          }
        }
      } : {}
    ) : {}
  }
}

# Monitoring Resources Output
output "monitoring_resources" {
  description = "Details of all monitoring resources created"
  value = {
    log_analytics = var.monitoring_configuration != null ? (
      var.monitoring_configuration.log_analytics != null ? {
        for key, la in azurerm_log_analytics_workspace.these : key => {
          id                  = la.id
          name                = la.name
          resource_group_name = la.resource_group_name
          workspace_id        = la.workspace_id
        }
      } : {}
    ) : {}
    alerts = var.monitoring_configuration != null ? (
      var.monitoring_configuration.alerts != null ? {
        for key, alert in azurerm_monitor_metric_alert.these : key => {
          id          = alert.id
          name        = alert.name
          description = alert.description
          severity    = alert.severity
        }
      } : {}
    ) : {}
  }
}

# Compute Resources Output
output "compute_resources" {
  description = "Details of all compute resources created"
  value = {
    virtual_machines = var.compute_configuration != null ? (
      var.compute_configuration.vms != null ? {
        for key, vm in azurerm_linux_virtual_machine.these : key => {
          id                = vm.id
          name              = vm.name
          size              = vm.size
          admin_username    = vm.admin_username
          private_ip       = azurerm_network_interface.these[key].private_ip_address
          public_ip        = try(azurerm_public_ip.vm[key].ip_address, null)
          resource_group   = vm.resource_group_name
          location         = vm.location
        }
      } : {}
    ) : {}
  }
}

# Storage Resources Output
output "storage_resources" {
  description = "Details of all storage resources created"
  value = {
    storage_accounts = var.storage_configuration != null ? (
      var.storage_configuration.storage_accounts != null ? {
        for key, sa in azurerm_storage_account.these : key => {
          id                  = sa.id
          name                = sa.name
          primary_access_key = sa.primary_access_key
          containers = try({
            for container_key, container in azurerm_storage_container.these : container_key => {
              id   = container.id
              name = container.name
            } if split("-", container_key)[0] == key
          }, {})
          file_shares = try({
            for share_key, share in azurerm_storage_share.these : share_key => {
              id   = share.id
              name = share.name
            } if split("-", share_key)[0] == key
          }, {})
        }
      } : {}
    ) : {}
  }
}
