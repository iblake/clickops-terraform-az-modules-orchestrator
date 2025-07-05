output "log_analytics" {
  description = "Details of all log analytics workspaces created"
  value = {
    for key, workspace in azurerm_log_analytics_workspace.these : key => {
      id   = workspace.id
      name = workspace.name
    }
  }
}

output "alerts" {
  description = "Details of all alerts created"
  value = {
    for key, alert in azurerm_monitor_metric_alert.these : key => {
      id   = alert.id
      name = alert.name
    }
  }
} 