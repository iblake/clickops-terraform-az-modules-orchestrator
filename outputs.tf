# Azure Orchestrator Outputs

# IAM Resources Output
output "iam_resources" {
  description = "Details of all IAM resources created"
  value = var.iam_configuration != null ? module.azure_lz_iam[0].resource_groups : {}
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
  value = var.monitoring_configuration != null ? {
    log_analytics = module.azure_lz_monitoring[0].log_analytics
    alerts = module.azure_lz_monitoring[0].alerts
  } : {}
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
