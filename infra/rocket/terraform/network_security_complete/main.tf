


# # Configure the Azure provider
# terraform {
#   required_providers {
#     azurerm = {
#       source  = "hashicorp/azurerm"
#       version = ">= 3.64.0"
#     }
#   }
# }

# provider "azurerm" {
#   features {}
# }

# # Create Resource Group
# # resource "azurerm_resource_group" "main" {
# #   name     = "rg-${var.unique}-dev"
# #   location = var.location
# # }

# resource "azurerm_resource_group" "main" {
#   name     = "${var.unique}-hub-1-rg"
#   location = var.location
# }

# resource "azurerm_resource_group" "spoke_rg" {
#   name     = "${var.unique}-spoke-1-rg"
#   location = var.location
# }

# # Create Virtual Networks
# resource "azurerm_virtual_network" "vnet1" {
#   name                = "${var.unique}-hub-westus-1-vnet"
#   address_space       = ["10.1.0.0/22"]
#   location            = azurerm_resource_group.main.location
#   resource_group_name = azurerm_resource_group.main.name
# }

# resource "azurerm_virtual_network" "vnet2" {
#   name                = "${var.unique}-spoke-westus-1-vnet"
#   address_space       = ["10.2.0.0/22"]
#   location            = azurerm_resource_group.spoke_rg.location
#   resource_group_name = azurerm_resource_group.spoke_rg.name
# }

# # Create Subnets
# resource "azurerm_subnet" "subnet1" {
#   name                 = "sn-1-${var.unique}"
#   resource_group_name  = azurerm_resource_group.main.name
#   virtual_network_name = azurerm_virtual_network.vnet1.name
#   address_prefixes     = ["10.0.0.0/24"]
# }

# resource "azurerm_subnet" "subnet2" {
#   name                 = "sn-2-${var.unique}"
#   resource_group_name  = azurerm_resource_group.spoke_rg.name
#   virtual_network_name = azurerm_virtual_network.vnet2.name
#   address_prefixes     = ["10.1.1.0/24"]
# }

# # Create VNet Peerings
# resource "azurerm_virtual_network_peering" "vnet1_to_vnet2" {
#   name                      = "peer-${var.unique}-vnet1-to-vnet2"
#   resource_group_name       = azurerm_resource_group.main.name
#   virtual_network_name      = azurerm_virtual_network.vnet1.name
#   remote_virtual_network_id = azurerm_virtual_network.vnet2.id
#   allow_virtual_network_access = true
# }

# resource "azurerm_virtual_network_peering" "vnet2_to_vnet1" {
#   name                      = "peer-${var.unique}-vnet2-to-vnet1"
#   resource_group_name       = azurerm_resource_group.spoke_rg.name
#   virtual_network_name      = azurerm_virtual_network.vnet2.name
#   remote_virtual_network_id = azurerm_virtual_network.vnet1.id
#   allow_virtual_network_access = true
# }

# # Create Bastion Public IP
# resource "azurerm_public_ip" "bastion_public_ip" {
#   name                = "BastionPublicIp"
#   resource_group_name = azurerm_resource_group.main.name
#   location            = azurerm_resource_group.main.location
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

# # Create Bastion Subnet
# resource "azurerm_subnet" "bastion_subnet" {
#   name                 = "AzureBastionSubnet"
#   resource_group_name  = azurerm_resource_group.main.name
#   virtual_network_name = azurerm_virtual_network.vnet1.name
#   address_prefixes     = ["10.1.0.0/26"]

#   # disable_private_endpoint_network_policies = true
#   # disable_private_link_service_network_policies = true
#   private_link_service_network_policies_enabled = false
#   private_endpoint_network_policies = "Disabled"
# }

# # Create Bastion Host
# resource "azurerm_bastion_host" "bastion_host" {
#   name                = "bh-${var.unique}"
#   location            = azurerm_resource_group.main.location
#   resource_group_name = azurerm_resource_group.main.name

#   ip_configuration {
#     name                 = "bastion_ip_config"
#     subnet_id            = azurerm_subnet.bastion_subnet.id
#     public_ip_address_id = azurerm_public_ip.bastion_public_ip.id
#   }
# }

# # Create App Service Plan
# resource "azurerm_service_plan" "app_plan" {
#   name                = "${var.unique}-app-plan"
#   location            = azurerm_resource_group.main.location
#   resource_group_name = azurerm_resource_group.main.name
#   os_type             = "Linux"
#   sku_name            = "P1v2"
# }

# # Create Web App
# resource "azurerm_linux_web_app" "web_app" {
#   name                = "webapp-${var.unique}"
#   location            = azurerm_resource_group.main.location
#   resource_group_name = azurerm_resource_group.main.name
#   service_plan_id     = azurerm_service_plan.app_plan.id

#   # linux_fx_version = "DOTNET|6.0"
#   site_config {}
# }

# # Create Subnet for Private Endpoint
# resource "azurerm_subnet" "private_endpoint_subnet" {
#   name                 = "sn-${var.unique}-app"
#   resource_group_name  = azurerm_resource_group.main.name
#   virtual_network_name = azurerm_virtual_network.vnet2.name
#   address_prefixes     = ["10.1.0.0/26"]

#   # disable_private_endpoint_network_policies = true
#   # disable_private_link_service_network_policies = true
# }

# # Create Private Endpoint
# resource "azurerm_private_endpoint" "web_app_private_endpoint" {
#   name                = "pe-app-${var.unique}"
#   location            = azurerm_resource_group.main.location
#   resource_group_name = azurerm_resource_group.main.name
#   subnet_id           = azurerm_subnet.private_endpoint_subnet.id

#   private_service_connection {
#     name                           = "pe-${var.unique}-web"
#     private_connection_resource_id = azurerm_linux_web_app.web_app.id
#     subresource_names              = ["sites"]
#     is_manual_connection           = false
#   }
# }

# # Create Private DNS Zone
# resource "azurerm_private_dns_zone" "dns_zone" {
#   name                = "privatelink.azurewebsites.net"
#   resource_group_name = azurerm_resource_group.main.name
# }

# # Link DNS Zone to VNet2
# resource "azurerm_private_dns_zone_virtual_network_link" "dns_zone_link" {
#   name                  = "vnet-privatelink-${var.unique}-websites"
#   resource_group_name   = azurerm_resource_group.main.name
#   private_dns_zone_name = azurerm_private_dns_zone.dns_zone.name
#   virtual_network_id    = azurerm_virtual_network.vnet2.id
#   registration_enabled  = false
# }

# # Create Network Security Group
# resource "azurerm_network_security_group" "nsg_jb" {
#   name                = "nsg-${var.unique}-jb"
#   location            = azurerm_resource_group.main.location
#   resource_group_name = azurerm_resource_group.main.name
# }

# # Create Network Interface for VM
# resource "azurerm_network_interface" "nic_jb" {
#   name                = "${var.unique}-nicjb"
#   location            = azurerm_resource_group.main.location
#   resource_group_name = azurerm_resource_group.main.name

#   ip_configuration {
#     name                          = "internal"
#     subnet_id                     = azurerm_subnet.subnet1.id
#     private_ip_address_allocation = "Dynamic"
#   }
# }

# # Associate NSG with NIC
# resource "azurerm_network_interface_security_group_association" "nic_nsg_assoc" {
#   network_interface_id      = azurerm_network_interface.nic_jb.id
#   network_security_group_id = azurerm_network_security_group.nsg_jb.id
# }

# # Create Virtual Machine
# resource "azurerm_windows_virtual_machine" "jumpbox_vm" {
#   name                  = "${var.unique}-jump"
#   location              = azurerm_resource_group.main.location
#   resource_group_name   = azurerm_resource_group.main.name
#   size                  = var.vm_size
#   admin_username        = var.admin_username
#   admin_password        = var.admin_password
#   network_interface_ids = [azurerm_network_interface.nic_jb.id]

#   os_disk {
#     name                 = "${var.unique}-disk"
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }

#   source_image_reference {
#     publisher = var.vm_image.publisher
#     offer     = var.vm_image.offer
#     sku       = var.vm_image.sku
#     version   = var.vm_image.version
#   }
# }
