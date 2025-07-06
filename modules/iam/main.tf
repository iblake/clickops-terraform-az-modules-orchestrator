# Copyright (c) 2024 Blake and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Resource Groups
resource "azurerm_resource_group" "rg" {
  for_each = var.resource_groups
  
  name     = each.value.name
  location = each.value.location
  tags     = each.value.tags
}

# Role Definitions
resource "azurerm_role_definition" "role" {
  for_each = var.roles
  
  name        = each.value.name
  description = each.value.description
  scope       = "/subscriptions/${var.subscription_id}"

  permissions {
    actions          = each.value.permissions[0].actions
    not_actions      = try(each.value.permissions[0].not_actions, [])
    data_actions     = try(each.value.permissions[0].data_actions, [])
    not_data_actions = try(each.value.permissions[0].not_data_actions, [])
  }
}

# Role Assignments
resource "azurerm_role_assignment" "assignment" {
  for_each = var.role_assignments
  
  scope                = each.value.scope
  role_definition_name = each.value.role_name
  principal_id         = each.value.principal_id
} 