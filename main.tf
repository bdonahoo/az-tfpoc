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
  name     = "az-tf-poc"
  location = "East US"
}

# configure vnet
resource "azurerm_virtual_network" "tf-poc-vnet" {
  name                = "tf-poc-vnet"
  resource_group_name = "az-tf-poc"
  location            = "East US"
  address_space       = var.vnet_address_space
}
variable "vpc_id" {
  default = "vpc-123"
}
# loop through subnets
# borrowed & modified from https://stackoverflow.com/questions/61900722/creating-subnet-in-a-loop-in-terraform
resource "azurerm_subnet" "tf-poc-vnet-subnets" {
  name                 = "Sub${count.index + 1}" #increment the count so the subnets are named correctly!
  count                = 4
  resource_group_name  = "az-tf-poc"
  virtual_network_name = "tf-poc-vnet"
  address_prefixes     = ["${element(var.subnet_address_space, count.index)}"]
}
