# Resource Groups
output "resource_groups" {
  description = "Map of created resource groups"
  value = {
    for k, v in azurerm_resource_group.rg : k => {
      id       = v.id
      name     = v.name
      location = v.location
      tags     = v.tags
    }
  }
}

# Role Definitions
output "roles" {
  description = "Map of created role definitions"
  value = {
    for k, v in azurerm_role_definition.role : k => {
      id          = v.role_definition_id
      name        = v.name
      description = v.description
    }
  }
}

# Role Assignments
output "role_assignments" {
  description = "Map of created role assignments"
  value = {
    for k, v in azurerm_role_assignment.assignment : k => {
      id           = v.id
      principal_id = v.principal_id
      scope        = v.scope
      role_name    = v.role_definition_name
    }
  }
} 