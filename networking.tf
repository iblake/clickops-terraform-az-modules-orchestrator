# Copyright (c) 2024 Blake and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Core networking
module "azure_lz_network" {
  count = var.network_configuration != null ? 1 : 0
  source = "./modules/networking"
  
  resource_groups = var.iam_configuration.resource_groups
  vnets = var.network_configuration.vnets
  subnets = local.flattened_subnets
  network_security_groups = var.network_configuration.network_security_groups
} 