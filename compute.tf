# Copyright (c) 2024 Blake and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Core compute
module "azure_lz_compute" {
  count = var.compute_configuration != null ? 1 : 0
  source = "./modules/compute"
  
  resource_groups = var.iam_configuration.resource_groups
  vms = var.compute_configuration.vms
  subnets = module.azure_lz_network[0].subnets
  get_vnet_key_for_subnet = local.get_vnet_key_for_subnet
}

 