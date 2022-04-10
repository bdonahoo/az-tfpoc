# create a password for the vms
resource "random_string" "vm-password" {
  length           = 16
  special          = true
  override_special = "/@!$"
}

# kv names must be globally unique; generate a random one
resource "random_id" "kv-name" {
  byte_length = 4
}
# store the password in a key vault
data "azurerm_client_config" "current" {}
resource "azurerm_key_vault" "poc-kv" {
  name                        = "poc-kv-${random_id.kv-name.hex}"
  location                    = var.region
  resource_group_name         = var.rg_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id           = data.azurerm_client_config.current.tenant_id
    object_id           = data.azurerm_client_config.current.object_id
    key_permissions     = ["Get", ]
    secret_permissions  = ["Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set", ]
    storage_permissions = ["Get", ]
  }
}
resource "azurerm_key_vault_secret" "vm-admin-secret" {
  name         = "vm-admin-credentials"
  depends_on   = [azurerm_key_vault.poc-kv]
  content_type = var.vm_user
  value        = random_string.vm-password.result
  key_vault_id = azurerm_key_vault.poc-kv.id
}
# create a bastion host
resource "azurerm_bastion_host" "bastionhost" {
  name                = "bastionhost"
  location            = var.region
  resource_group_name = var.rg_name

  ip_configuration {
    name                 = "bastionconfig"
    subnet_id            = var.bastion-subnet-id
    public_ip_address_id = var.bastion-pip-id
  }
}
# availability set modified from hashicorp docs example 
resource "azurerm_availability_set" "rhel_availability_set" {
  name                        = "rhel-aset"
  location                    = var.region
  resource_group_name         = var.rg_name
  platform_fault_domain_count = 2
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
    sku       = "7-LVM"
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
    admin_username = var.vm_user
    admin_password = random_string.vm-password.result
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
    sku       = "7-LVM"
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
    admin_username = var.vm_user
    admin_password = random_string.vm-password.result
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
    sku       = "7-LVM"
    version   = "latest"
  }
  storage_os_disk {
    name              = "apache-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "apache"
    admin_username = var.vm_user
    admin_password = random_string.vm-password.result
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
}
# install apache server
resource "azurerm_virtual_machine_extension" "apache-install" {
  name                 = "apache-install"
  virtual_machine_id   = azurerm_virtual_machine.apache.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "sudo yum install httpd -y && sudo systemctl enable httpd && sudo systemctl start httpd && firewall-cmd --permanent --zone=public --add-port=80/tcp && firewall-cmd --reload"
    }
SETTINGS
}