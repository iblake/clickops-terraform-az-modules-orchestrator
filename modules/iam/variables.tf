variable "resource_groups" {
  description = "Map of resource groups"
  type = map(object({
    name     = string
    location = string
    tags     = optional(map(string))
  }))
}

variable "roles" {
  description = "Map of role definitions"
  type = map(object({
    name        = string
    description = string
    permissions = list(object({
      actions          = list(string)
      not_actions      = optional(list(string))
      data_actions     = optional(list(string))
      not_data_actions = optional(list(string))
    }))
  }))
  default = {}
}

variable "role_assignments" {
  description = "Map of role assignments"
  type = map(object({
    role_name    = string
    principal_id = string
    scope        = string
  }))
  default = {}
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
} 