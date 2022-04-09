output "resource-group-name" {
  value = azurerm_resource_group.az-tf-poc.name
}
output "rhel01-nic-id" {
  value = azurerm_network_interface.rhel-nics[0].id
}
output "rhel02-nic-id" {
  value = azurerm_network_interface.rhel-nics[1].id
}
output "apache-nic-id" {
  value = azurerm_network_interface.apache-nic.id
}
output "subnet-ids" {
  value = [azurerm_subnet.tf-poc-vnet-subnets[0].id, azurerm_subnet.tf-poc-vnet-subnets[1].id, azurerm_subnet.tf-poc-vnet-subnets[2].id, azurerm_subnet.tf-poc-vnet-subnets[3].id]
}

