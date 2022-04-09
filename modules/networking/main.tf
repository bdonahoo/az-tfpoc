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