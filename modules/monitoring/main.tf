# Copyright (c) 2024 Blake and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Log Analytics Workspaces
resource "azurerm_log_analytics_workspace" "these" {
  for_each = var.log_analytics
  
  name                = each.value.name
  location            = var.resource_groups[each.value.resource_group_key].location
  resource_group_name = var.resource_groups[each.value.resource_group_key].name
  sku                 = "PerGB2018"
  retention_in_days   = try(each.value.retention_in_days, 30)
  tags                = try(each.value.tags, null)
}

# Metric Alerts
resource "azurerm_monitor_metric_alert" "these" {
  for_each = var.alerts
  
  name                = each.value.name
  resource_group_name = var.resource_groups[each.value.resource_group_key].name
  scopes              = each.value.scopes
  description         = each.value.description
  severity            = each.value.severity
  frequency           = each.value.frequency
  window_size         = each.value.window_size
  tags                = try(each.value.tags, null)

  criteria {
    metric_namespace = each.value.criteria.metric_namespace
    metric_name      = each.value.criteria.metric_name
    aggregation      = each.value.criteria.aggregation
    operator         = each.value.criteria.operator
    threshold        = each.value.criteria.threshold
  }

  dynamic "action" {
    for_each = try(each.value.action, null) != null ? [each.value.action] : []
    content {
      action_group_id = action.value.action_group_id
      webhook_properties = try(action.value.webhook, null) != null ? {
        "webhook" = action.value.webhook
      } : null
    }
  }
} 