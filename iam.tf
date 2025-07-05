# Copyright (c) 2024 Blake and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# IAM Resources
resource "azurerm_resource_group" "these" {
  for_each = var.iam_configuration != null ? (
    var.iam_configuration.resource_groups != null ? var.iam_configuration.resource_groups : {}
  ) : {}

  name     = each.value.name
  location = coalesce(each.value.location, local.default_location)
  tags     = each.value.tags
}

resource "azurerm_role_definition" "these" {
  for_each = var.iam_configuration != null ? (
    var.iam_configuration.roles != null ? var.iam_configuration.roles : {}
  ) : {}

  name        = each.value.name
  description = each.value.description
  scope       = "/subscriptions/${local.subscription_id}"

  permissions {
    actions          = each.value.permissions[0].actions
    not_actions      = try(each.value.permissions[0].not_actions, [])
    data_actions     = try(each.value.permissions[0].data_actions, [])
    not_data_actions = try(each.value.permissions[0].not_data_actions, [])
  }
}

resource "azurerm_role_assignment" "these" {
  for_each = var.iam_configuration != null ? (
    var.iam_configuration.role_assignments != null ? var.iam_configuration.role_assignments : {}
  ) : {}

  scope                = each.value.scope
  role_definition_name = each.value.role_name
  principal_id         = each.value.principal_id
} 