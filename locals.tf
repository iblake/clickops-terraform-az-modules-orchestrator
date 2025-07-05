locals {
  flattened_subnets = merge([
    for vnet_key, vnet in var.configuration.networking.vnets : {
      for subnet_key, subnet in vnet.subnets : "${vnet_key}_${subnet_key}" => merge(subnet, {
        vnet_key = vnet_key
        resource_group_key = vnet.resource_group_key
      })
    }
  ]...)
} 