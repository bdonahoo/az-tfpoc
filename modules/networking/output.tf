output "resource-group-name" {
  value = azurerm_resource_group.az-tf-poc.name
}
output "rhel01-nic-id" {
  value = azurerm_network_interface.rhel01-nic.id
}
output "rhel02-nic-id" {
  value = azurerm_network_interface.rhel02-nic.id
}
output "apache-nic-id" {
  value = azurerm_network_interface.apache-nic.id
}

