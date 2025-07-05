# Create resource groups
resource "azurerm_resource_group" "rg" {
  for_each = var.configuration.vms

  name     = var.resource_group_ids[each.value.resource_group_id]
  location = "eastus"  # Por defecto usamos eastus, podríamos hacerlo configurable si es necesario
}

# Create public IPs
resource "azurerm_public_ip" "pip" {
  for_each = {
    for k, v in var.configuration.vms : k => v
    if v.public_ip
  }

  name                = "${each.value.name}-pip"
  resource_group_name = azurerm_resource_group.rg[each.key].name
  location            = azurerm_resource_group.rg[each.key].location
  allocation_method   = try(each.value.network_interface.ip_configuration.public_ip_address.allocation_method, "Static")
  sku                = try(each.value.network_interface.ip_configuration.public_ip_address.sku, "Basic")
}

# Create network interfaces
resource "azurerm_network_interface" "nic" {
  for_each = var.configuration.vms

  name                = "${each.value.name}-nic"
  location            = azurerm_resource_group.rg[each.key].location
  resource_group_name = azurerm_resource_group.rg[each.key].name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet[each.key].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id         = each.value.public_ip ? azurerm_public_ip.pip[each.key].id : null
  }
}

# Create virtual network
resource "azurerm_virtual_network" "vnet" {
  for_each = var.configuration.vms

  name                = "${each.value.name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg[each.key].location
  resource_group_name = azurerm_resource_group.rg[each.key].name
}

# Create subnet
resource "azurerm_subnet" "subnet" {
  for_each = var.configuration.vms

  name                 = "${each.value.name}-subnet"
  resource_group_name  = azurerm_resource_group.rg[each.key].name
  virtual_network_name = azurerm_virtual_network.vnet[each.key].name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create Linux VMs
resource "azurerm_linux_virtual_machine" "vm" {
  for_each = var.configuration.vms

  name                = each.value.name
  resource_group_name = azurerm_resource_group.rg[each.key].name
  location            = azurerm_resource_group.rg[each.key].location
  size                = each.value.size
  admin_username      = each.value.admin_username

  network_interface_ids = [
    azurerm_network_interface.nic[each.key].id,
  ]

  admin_ssh_key {
    username   = each.value.admin_username
    public_key = each.value.admin_ssh_key
  }

  os_disk {
    name                 = each.value.os_disk.name
    caching              = each.value.os_disk.caching
    storage_account_type = each.value.os_disk.storage_account_type
    disk_size_gb         = each.value.os_disk.disk_size_gb
  }

  source_image_reference {
    publisher = each.value.source_image_reference.publisher
    offer     = each.value.source_image_reference.offer
    sku       = each.value.source_image_reference.sku
    version   = each.value.source_image_reference.version
  }
} 