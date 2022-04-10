# storage account with network rules taken directly from example here https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account
resource "random_id" "storage-account-name" {
  byte_length = 6
}

resource "azurerm_storage_account" "tf-poc-storage" {
  name                     = "pocstorage${random_id.storage-account-name.hex}"
  resource_group_name      = var.rg_name
  location                 = var.region
  account_tier             = "Standard"
  account_replication_type = "LRS"
  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = var.subnet-ids
  }
}