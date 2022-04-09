# tf providers taken from hashicorp azurerm docs
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}
provider "azurerm" {
  features {}
}
# defines rg, vnet, subnets, and nics
module "networking" {
  source = "./modules/networking"
  subnet_address_space = var.subnet_address_space
  vnet_address_space = var.vnet_address_space
  region = var.region
  rg_name = var.rg_name
}
# defines availability set and virtual machines
module "compute" {
  source = "./modules/compute"
  rg_name = module.networking.resource-group-name
  region = var.region
  rhel01-nic-id = module.networking.rhel01-nic-id
  rhel02-nic-id = module.networking.rhel02-nic-id
  apache-nic-id = module.networking.apache-nic-id
  machine-size = var.machine-size
}
