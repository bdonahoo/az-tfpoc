# availability set modified from hashicorp docs example 
resource "azurerm_availability_set" "rhel_availability_set" {
  name                = "rhel-aset"
  location            = var.region
  resource_group_name = var.rg_name
}
# 2 rhel boxes in sub1
resource "azurerm_virtual_machine" "rhel01" {
  name                  = "rhel01"
  location              = var.region
  resource_group_name   = var.rg_name
  network_interface_ids = [var.rhel01-nic-id]
  vm_size               = var.machine-size
  availability_set_id   = azurerm_availability_set.rhel_availability_set.id

  storage_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "8_4"
    version   = "latest"
  }
  storage_os_disk {
    name              = "rhel01-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = 256
  }
  os_profile {
    computer_name  = "rhel01"
    admin_username = "pocadmin"
    admin_password = "var.vm_password"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
}
resource "azurerm_virtual_machine" "rhel02" {
  name                  = "rhel02"
  location              = var.region
  resource_group_name   = var.rg_name
  network_interface_ids = [var.rhel02-nic-id]
  vm_size               = var.machine-size
  availability_set_id   = azurerm_availability_set.rhel_availability_set.id

  storage_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "8_4"
    version   = "latest"
  }
  storage_os_disk {
    name              = "rhel02-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = 256
  }
  os_profile {
    computer_name  = "rhel02"
    admin_username = "pocadmin"
    admin_password = "var.vm_password"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
}
resource "azurerm_virtual_machine" "apache" {
  name                  = "apache"
  location              = var.region
  resource_group_name   = var.rg_name
  network_interface_ids = [var.apache-nic-id]
  vm_size               = var.machine-size
  storage_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "8_4"
    version   = "latest"
  }
  storage_os_disk {
    name              = "apache-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = 32
  }
  os_profile {
    computer_name  = "apache"
    admin_username = "pocadmin"
    admin_password = "var.vm_password"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
}