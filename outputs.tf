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
  value = var.network_configuration != null ? module.azure_lz_network[0].virtual_networks : {}
}

# Security Resources Output
output "security_resources" {
  description = "Details of all security resources created"
  value = var.security_configuration != null ? module.azure_lz_security[0].key_vaults : {}
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
  value = var.compute_configuration != null ? module.azure_lz_compute[0].virtual_machines : {}
}

# Storage Resources Output
output "storage_resources" {
  description = "Details of all storage resources created"
  value = var.storage_configuration != null ? module.azure_lz_storage[0].storage_accounts : {}
}
