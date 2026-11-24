output "private_ip" {
  description = "privateip of created vm"
  value       = azurerm_network_interface.Temp.private_ip_address

}
output "public_ip" {
  description = "VM_ip"
  value       = azurerm_public_ip.Temp.ip_address
}
output "vm-id" {
  description = "vm-id"
  value       = local.is_linux ? azurerm_linux_virtual_machine.Temp[0].id : azurerm_windows_virtual_machine.Temp[0].id
}