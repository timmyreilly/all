output "vm_id" {
  value = azurerm_virtual_machine.main.id
}

output "vm_private_ip" {
  value = azurerm_network_interface.main.private_ip_address
}

output "vm_public_ip" {
  value = data.azurerm_public_ip.waited_public_ip.ip_address
}

output "vm_name" {
  value = azurerm_virtual_machine.main.name
}