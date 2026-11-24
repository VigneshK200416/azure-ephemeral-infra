output "subnet" {
  value = azurerm_subnet.Temp.id
}
output "nsg_name" {
  value = azurerm_network_security_group.Temp.name
}