# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.64.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Variables (assuming you have these defined elsewhere)
# variable "unique" {}
# variable "location" {}
# variable "vm_size" {}
# variable "admin_username" {}
# variable "admin_password" {}
# variable "vm_image" {
#   type = object({
#     publisher = string
#     offer     = string
#     sku       = string
#     version   = string
#   })
# }

# Create Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.unique}-dev"
  location = var.location
}

# Create Virtual Networks
resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet-1-${var.unique}"
  address_space       = ["10.0.0.0/22"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_virtual_network" "vnet2" {
  name                = "vnet-2-${var.unique}"
  address_space       = ["10.1.0.0/22"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Create Subnets
resource "azurerm_subnet" "subnet1" {
  name                 = "sn-1-${var.unique}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "subnet2" {
  name                 = "sn-2-${var.unique}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes     = ["10.1.1.0/24"]
}

# Bastion Subnet
resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.1.0/26"]

  private_link_service_network_policies_enabled = false
  private_endpoint_network_policies = "Disabled"
}

# Firewall Subnet
resource "azurerm_subnet" "firewall_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create VNet Peerings
resource "azurerm_virtual_network_peering" "vnet1_to_vnet2" {
  name                      = "peer-${var.unique}-vnet1-to-vnet2"
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.vnet1.name
  remote_virtual_network_id = azurerm_virtual_network.vnet2.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "vnet2_to_vnet1" {
  name                      = "peer-${var.unique}-vnet2-to-vnet1"
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.vnet2.name
  remote_virtual_network_id = azurerm_virtual_network.vnet1.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# Create Bastion Public IP
resource "azurerm_public_ip" "bastion_public_ip" {
  name                = "BastionPublicIp"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create Bastion Host
resource "azurerm_bastion_host" "bastion_host" {
  name                = "bh-${var.unique}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                 = "bastion_ip_config"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_public_ip.id
  }
}

# Create App Service Plan
resource "azurerm_service_plan" "app_plan" {
  name                = "${var.unique}-app-plan"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "B1"
}

# Create Web App
resource "azurerm_linux_web_app" "web_app" {
  name                = "webbapp-${var.unique}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.app_plan.id

  site_config {
  }
  app_settings = {
    SCM_DO_BUILD_DURING_DEPLOYMENT = "true"
  }
}

# Create Subnet for Private Endpoint
resource "azurerm_subnet" "private_endpoint_subnet" {
  name                 = "sn-${var.unique}-app"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes     = ["10.1.0.0/26"]

#   private_endpoint_network_policies_enabled = false
  private_endpoint_network_policies = "Disabled"

}

# Create Private Endpoint
resource "azurerm_private_endpoint" "web_app_private_endpoint" {
  name                = "pep-app-${var.unique}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoint_subnet.id

  private_service_connection {
    name                           = "pep-${var.unique}-web"
    private_connection_resource_id = azurerm_linux_web_app.web_app.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }
}

# Create Private DNS Zone
resource "azurerm_private_dns_zone" "dns_zone" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.main.name
}

# Link DNS Zone to VNet2
resource "azurerm_private_dns_zone_virtual_network_link" "dns_zone_link" {
  name                  = "vnet-privatelink-${var.unique}-websites"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet2.id
  registration_enabled  = false
}

# Create Network Security Group
resource "azurerm_network_security_group" "nsg_jb" {
  name                = "nsg-${var.unique}-jb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Create Network Interface for VM
resource "azurerm_network_interface" "nic_jb" {
  name                = "${var.unique}-nicjb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "nic_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic_jb.id
  network_security_group_id = azurerm_network_security_group.nsg_jb.id
}

# Create Virtual Machine
resource "azurerm_windows_virtual_machine" "jumpbox_vm" {
  name                  = "${var.unique}-jump"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  size                  = var.vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.nic_jb.id]

  os_disk {
    name                 = "${var.unique}-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.vm_image.publisher
    offer     = var.vm_image.offer
    sku       = var.vm_image.sku
    version   = var.vm_image.version
  }
}

# =========================
# Azure Firewall Integration
# =========================

# Public IP for Firewall
resource "azurerm_public_ip" "firewall_pip" {
  name                = "pip-fw-${var.unique}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Azure Firewall
resource "azurerm_firewall" "firewall" {
  name                = "fw-${var.unique}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "AZFW_VNet" # Standard SKU
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "ipconfig"
    subnet_id            = azurerm_subnet.firewall_subnet.id
    public_ip_address_id = azurerm_public_ip.firewall_pip.id
  }

  depends_on = [azurerm_public_ip.firewall_pip, azurerm_subnet.firewall_subnet]
}

# Route Table for vnet1
resource "azurerm_route_table" "rt_vnet1" {
  name                = "rt-${var.unique}-vnet1"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

resource "azurerm_route" "route_vnet1_internet" {
  name                   = "route-internet"
  resource_group_name    = azurerm_resource_group.main.name
  route_table_name       = azurerm_route_table.rt_vnet1.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
}

# Associate Route Table with Subnets in vnet1 (excluding AzureFirewallSubnet)
resource "azurerm_subnet_route_table_association" "rt_assoc_vnet1_subnet1" {
  subnet_id      = azurerm_subnet.subnet1.id
  route_table_id = azurerm_route_table.rt_vnet1.id
}

# resource "azurerm_subnet_route_table_association" "rt_assoc_vnet1_bastion" {
#   subnet_id      = azurerm_subnet.bastion_subnet.id
#   route_table_id = azurerm_route_table.rt_vnet1.id
# }

# Route Table for vnet2
resource "azurerm_route_table" "rt_vnet2" {
  name                = "rt-${var.unique}-vnet2"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

resource "azurerm_route" "route_vnet2_internet" {
  name                   = "route-internet"
  resource_group_name    = azurerm_resource_group.main.name
  route_table_name       = azurerm_route_table.rt_vnet2.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
}

# Associate Route Table with Subnets in vnet2 (excluding private endpoint subnet)
resource "azurerm_subnet_route_table_association" "rt_assoc_vnet2_subnet2" {
  subnet_id      = azurerm_subnet.subnet2.id
  route_table_id = azurerm_route_table.rt_vnet2.id
}

resource "azurerm_subnet_route_table_association" "rt_assoc_vnet2_private_endpoint" {
  subnet_id      = azurerm_subnet.private_endpoint_subnet.id
  route_table_id = azurerm_route_table.rt_vnet2.id
}

# Firewall Network Rule Collection (Allow DNS)
resource "azurerm_firewall_network_rule_collection" "network_rule_collection" {
  name                = "net-rule-collection-${var.unique}"
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = azurerm_resource_group.main.name
  priority            = 100
  action              = "Allow"

  rule {
    name = "allow-dns"

    source_addresses = ["10.0.0.0/22", "10.1.0.0/22"]
    destination_addresses = ["*"]
    destination_ports     = ["53"]
    protocols             = ["TCP", "UDP"]
  }
}

# Firewall Application Rule Collection (Allow GitHub)
resource "azurerm_firewall_application_rule_collection" "app_rule_collection" {
  name                = "app-rule-collection-${var.unique}"
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = azurerm_resource_group.main.name
  priority            = 200
  action              = "Allow"

  rule {
    # name     = "allow-github"
    # source_addresses = ["10.0.0.0/22", "10.1.0.0/22"]
    # protocol = {
    #     protocol_type = "Https"
    #     port          = 443
    # }
    # target_fqdns = ["github.com", "*.github.com"]

    name = "allow-github"

    source_addresses = ["10.0.0.0/22", "10.1.0.0/22"]

    target_fqdns = ["github.com", "*.github.com"]

    protocol {
      port = "443"
      type = "Https"
  }
  }
}

# Optional: Allow Azure services (e.g., for private endpoints)
resource "azurerm_firewall_network_rule_collection" "network_rule_collection_azure" {
  name                = "net-rule-collection-azure-${var.unique}"
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = azurerm_resource_group.main.name
  priority            = 150
  action              = "Allow"

  rule {
    name = "allow-azure-services"

    source_addresses      = ["10.0.0.0/22", "10.1.0.0/22"]
    destination_addresses = ["AzureCloud"]
    destination_ports     = ["*"]
    protocols             = ["Any"]
  }
}
