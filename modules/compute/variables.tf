variable "configuration" {
  description = "VM configuration object"
  type = object({
    vms = map(object({
      name                = string
      resource_group_name = string
      location           = string
      size               = string
      admin_username     = string
      admin_ssh_key      = string
      subnet_id          = string
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
      public_ip = optional(object({
        name              = string
        allocation_method = string
        sku              = string
      }))
      tags = optional(map(string))
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