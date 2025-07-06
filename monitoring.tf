# Copyright (c) 2024 Blake and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Core monitoring
module "azure_lz_monitoring" {
  count = var.monitoring_configuration != null ? 1 : 0
  source = "./modules/monitoring"
  
  resource_groups = var.iam_configuration.resource_groups
  log_analytics = var.monitoring_configuration.log_analytics
  alerts = var.monitoring_configuration.alerts
} 