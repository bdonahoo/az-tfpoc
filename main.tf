# tf providers taken from hashicorp azurerm docs
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# create a resource group
resource "azurerm_resource_group" "az-tf-poc" {
  name     = var.rg_name
  location = var.region
}

# configure vnet
resource "azurerm_virtual_network" "tf-poc-vnet" {
  name                = "tf-poc-vnet"
  resource_group_name = var.rg_name
  location            = var.region
  address_space       = var.vnet_address_space
}
# loop through subnets
# borrowed & modified from https://stackoverflow.com/questions/61900722/creating-subnet-in-a-loop-in-terraform
resource "azurerm_subnet" "tf-poc-vnet-subnets" {
  name                 = "Sub${count.index + 1}" #increment the count so the subnets are named correctly!
  count                = 4
  resource_group_name  = var.rg_name
  virtual_network_name = "tf-poc-vnet"
  address_prefixes     = ["${element(var.subnet_address_space, count.index)}"]
}
# availability set modified from hashicorp docs example 

resource "azurerm_availability_set" "rhel_availability_set" {
  name                = "rhel-aset"
  location            = var.region
  resource_group_name = var.rg_name
}
# create nics for the VMs in sub1
resource "azurerm_network_interface" "rhel01-nic" {
  name                = "rhel01-nic"
  location            = var.region
  resource_group_name = var.rg_name
  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.tf-poc-vnet-subnets[0].id
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_network_interface" "rhel02-nic" {
  name                = "rhel02-nic"
  location            = var.region
  resource_group_name = var.rg_name
  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.tf-poc-vnet-subnets[0].id
    private_ip_address_allocation = "Dynamic"
  }
}
# nic for the apache box in sub3
resource "azurerm_network_interface" "apache-nic" {
  name                = "apache-nic"
  location            = var.region
  resource_group_name = var.rg_name
  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.tf-poc-vnet-subnets[2].id
    private_ip_address_allocation = "Dynamic"
  }
}
# 2 rhel boxes in sub1
resource "azurerm_virtual_machine" "rhel01" {
  name                  = "rhel01"
  location              = var.region
  resource_group_name   = var.rg_name
  network_interface_ids = [azurerm_network_interface.rhel01-nic.id]
  vm_size               = "Standard_DS1_v2"
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
  network_interface_ids = [azurerm_network_interface.rhel01-nic.id]
  vm_size               = "Standard_DS1_v2"
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
  network_interface_ids = [azurerm_network_interface.rhel01-nic.id]
  vm_size               = "Standard_DS1_v2"
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