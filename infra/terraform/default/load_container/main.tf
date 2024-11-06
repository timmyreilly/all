/*
Creates: 

*/


provider "azurerm" {
  version         = "=2.0.0"
  subscription_id = var.subscription_id
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "Default-Web-WestUS"
  location = "West US"
}

resource "azurerm_dns_zone" "example" {
  name                = "timmyreilly.com"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_cdn_frontdoor_profile" "prodFrontDoor" {
  name                = "prodFrontDoor"
  resource_group_name = azurerm_resource_group.example.name
  sku_name            = "Standard_AzureFrontDoor"
}

resource "azurerm_cdn_frontdoor_custom_domain" "vpn_timmyreilly_com" {
  name                     = "vpn-timmyreilly-com-0897"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.prodFrontDoor.id
  dns_zone_id              = azurerm_dns_zone.example.id
  host_name                = "vpn.timmyreilly.com"

  tls {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}

resource "azurerm_cdn_frontdoor_custom_domain" "moolah_timmyreilly_com" {
  name                     = "moolah-timmyreilly-com"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.prodFrontDoor.id
  dns_zone_id              = azurerm_dns_zone.example.id
  host_name                = "moolah.timmyreilly.com"

  tls {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}

resource "azurerm_cdn_frontdoor_origin_group" "default_origin_group" {
  name                     = "default-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.prodFrontDoor.id

  health_probe {
    path                    = "/"
    protocol                = "Http"
    interval_in_seconds     = 100
    request_type            = "HEAD"
  }

  load_balancing {
    sample_size                        = 4
    successful_samples_required        = 3
    additional_latency_in_milliseconds = 50
  }
}

resource "azurerm_cdn_frontdoor_origin" "azure_websites" {
  name                     = "azurewebsitestimmyreilly"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.default_origin_group.id
  host_name                = "timmyreilly.azurewebsites.net"
  http_port                = 80
  https_port               = 443
  priority                 = 1
  weight                   = 1000
}

resource "azurerm_cdn_frontdoor_endpoint" "home_endpoint" {
  name                     = "t-home"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.prodFrontDoor.id

  route {
    name           = "default-route"
    origin_group_id = azurerm_cdn_frontdoor_origin_group.default_origin_group.id
    patterns_to_match = ["/*"]
    https_redirect    = "Enabled"
  }
}


/*
resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}${var.tag_module_id}-azdoagent"
  location              = var.resource_group_location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "${var.prefix}${var.tag_module_id}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

data "azurerm_public_ip" "waited_public_ip" { 
  name = azurerm_public_ip.main.name
  resource_group_name = var.resource_group_name
  depends_on = [azurerm_virtual_machine.main]
}
*/