# region to deploy into
variable "region" {}
# resource group name
variable "rg_name" {}
# nic IDs
variable "rhel01-nic-id" {}
variable "rhel02-nic-id" {}
variable "apache-nic-id" {}
variable "machine-size" {}
variable "vm_user" {
  default = "pocadmin"
}
variable "bastion-pip-id" {}
variable "bastion-subnet-id" {}