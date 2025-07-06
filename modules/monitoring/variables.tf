variable "resource_groups" {
  description = "Map of resource groups"
  type = map(object({
    name     = string
    location = string
    tags     = optional(map(string))
  }))
}

variable "log_analytics" {
  description = "Map of log analytics workspaces"
  type = map(object({
    name                = string
    resource_group_key = string
    retention_in_days   = optional(number)
    tags                = optional(map(string))
  }))
  default = {}
}

variable "alerts" {
  description = "Map of metric alerts"
  type = map(object({
    name                = string
    resource_group_key = string
    scopes             = list(string)
    description        = string
    severity           = number
    frequency          = string
    window_size        = string
    criteria = object({
      metric_namespace = string
      metric_name     = string
      aggregation     = string
      operator        = string
      threshold       = number
    })
    action = optional(object({
      action_group_id = string
      webhook         = optional(string)
    }))
    tags = optional(map(string))
  }))
  default = {}
} 