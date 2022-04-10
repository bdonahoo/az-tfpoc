provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
# defines rg, vnet, subnets, and nics
module "networking" {
  source               = "./modules/networking"
  subnet_address_space = var.subnet_address_space
  vnet_address_space   = var.vnet_address_space
  region               = var.region
  rg_name              = var.rg_name
}
# defines availability set and virtual machines
module "compute" {
  depends_on        = [module.networking]
  source            = "./modules/compute"
  rg_name           = module.networking.resource-group-name
  region            = var.region
  rhel01-nic-id     = module.networking.rhel01-nic-id
  rhel02-nic-id     = module.networking.rhel02-nic-id
  apache-nic-id     = module.networking.apache-nic-id
  machine-size      = var.machine-size
  bastion-pip-id    = module.networking.bastion-pip-id
  bastion-subnet-id = module.networking.bastion-subnet-id
}
module "storage" {
  source     = "./modules/storage"
  depends_on = [module.networking]
  rg_name    = module.networking.resource-group-name
  region     = var.region
  subnet-ids = module.networking.subnet-ids
}
