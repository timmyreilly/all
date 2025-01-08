output "resource_group_name" {
  description = "The name of the Resource Group."
  value       = azurerm_resource_group.main.name
}

output "web_app_default_hostname" {
  description = "The default hostname of the Web App."
  value       = azurerm_linux_web_app.web_app.default_hostname
}

output "bastion_host_id" {
  description = "The ID of the Bastion Host."
  value       = azurerm_bastion_host.bastion_host.id
}

output "virtual_machine_id" {
  description = "The ID of the Virtual Machine."
  value       = azurerm_windows_virtual_machine.jumpbox_vm.id
}

output "web_app_name" {
  description = "The name of the Web App."
  value       = azurerm_linux_web_app.web_app.name
}

output "app_service_plan_name" {
  description = "The name of the App Service Plan."
  value       = azurerm_service_plan.app_plan.name
}
