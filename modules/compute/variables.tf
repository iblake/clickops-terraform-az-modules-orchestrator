variable "configuration" {
  description = "VM configuration object"
  type = object({
    vms = map(object({
      name                = string
      resource_group_id   = string
      subnet_id          = string
      size               = string
      admin_username     = string
      admin_ssh_key      = string
      public_ip         = bool
      os_disk = object({
        name                 = optional(string)
        caching              = string
        storage_account_type = string
        disk_size_gb        = number
      })
      source_image_reference = object({
        publisher = string
        offer     = string
        sku       = string
        version   = string
      })
    }))
  })
}

variable "resource_group_ids" {
  description = "Map of resource group keys to their IDs"
  type = map(string)
}

variable "subnet_ids" {
  description = "Map of subnet keys to their IDs"
  type = map(string)
} 