variable "resource_groups" {
  description = "Map of resource groups"
  type = map(object({
    name     = string
    location = string
    tags     = optional(map(string))
  }))
}

variable "vnets" {
  description = "Map of virtual networks"
  type = any
}

variable "subnets" {
  description = "Map of flattened subnets"
  type = any
}

variable "network_security_groups" {
  description = "Map of network security groups"
  type = any
}
