variable "resource_groups" {
  description = "Map of resource groups"
  type = map(object({
    name     = string
    location = string
    tags     = optional(map(string))
  }))
}

variable "vms" {
  description = "Map of virtual machines"
  type = map(object({
    name                = string
    resource_group_key  = string
    location           = optional(string)
    size               = string
    admin_username     = string
    admin_ssh_key      = string
    os_disk = object({
      name                 = optional(string)
      caching             = string
      storage_account_type = string
      disk_size_gb        = number
    })
    source_image_reference = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })
    network_interface = object({
      name      = optional(string)
      subnet_key = string
      ip_configuration = object({
        name                          = optional(string)
        private_ip_address_allocation = string
        private_ip_address           = optional(string)
        public_ip_address = optional(object({
          name              = string
          allocation_method = string
          sku              = string
          tags             = optional(map(string))
        }))
      })
    })
    tags = optional(map(string))
  }))
}

variable "subnets" {
  description = "Map of subnets"
  type = map(object({
    id                 = string
    name               = string
    resource_group     = string
    virtual_network    = string
    address_prefixes   = list(string)
  }))
}

variable "get_vnet_key_for_subnet" {
  description = "Map to get vnet key for a given subnet key"
  type        = map(string)
} 