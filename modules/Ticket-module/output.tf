output "Resource_group" {
  value = azurerm_resource_group.Temp.name
}
output "Resource_group_location" {
  value = azurerm_resource_group.Temp.location
}
output "ticket_id" {
  value = azurerm_resource_group.Temp.tags["ticket_id"]
}