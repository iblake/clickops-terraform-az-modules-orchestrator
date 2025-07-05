variable "resource_groups" {
  description = "Map of resource groups"
  type = map(object({
    name     = string
    location = string
    tags     = optional(map(string))
  }))
}

variable "storage_accounts" {
  description = "Map of storage accounts"
  type = any
}

variable "storage_containers" {
  description = "Map of storage containers"
  type = any
}

variable "storage_shares" {
  description = "Map of storage file shares"
  type = any
}
