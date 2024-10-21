/*
Creates: 

*/

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location_west_us
}

resource "azurerm_dns_zone" "dnszones_timmyreilly_com" {
  name                = var.dnszones_timmyreilly_com_name
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_app_service_domain" "domains_timmyreilly_com" {
  name                = var.domains_timmyreilly_com_name
  resource_group_name = azurerm_resource_group.main.name
  location            = "global"

  contact {
    admin {
      email       = var.domains_timmyreilly_com_email
      first_name  = var.domains_timmyreilly_com_nameFirst
      last_name   = var.domains_timmyreilly_com_nameLast
      phone       = var.domains_timmyreilly_com_phone
      address1    = "123 Main St"
      city        = "Seattle"
      state       = "WA"
      postal_code = "98101"
      country     = "US"
    }
    billing {
      email       = var.domains_timmyreilly_com_email_1
      first_name  = var.domains_timmyreilly_com_nameFirst_1
      last_name   = var.domains_timmyreilly_com_nameLast_1
      phone       = var.domains_timmyreilly_com_phone_1
      address1    = "123 Main St"
      city        = "Seattle"
      state       = "WA"
      postal_code = "98101"
      country     = "US"
    }
    registrant {
      email       = var.domains_timmyreilly_com_email_2
      first_name  = var.domains_timmyreilly_com_nameFirst_2
      last_name   = var.domains_timmyreilly_com_nameLast_2
      phone       = var.domains_timmyreilly_com_phone_2
      address1    = "123 Main St"
      city        = "Seattle"
      state       = "WA"
      postal_code = "98101"
      country     = "US"
    }
    tech {
      email       = var.domains_timmyreilly_com_email_3
      first_name  = var.domains_timmyreilly_com_nameFirst_3
      last_name   = var.domains_timmyreilly_com_nameLast_3
      phone       = var.domains_timmyreilly_com_phone_3
      address1    = "123 Main St"
      city        = "Seattle"
      state       = "WA"
      postal_code = "98101"
      country     = "US"
    }
  }

  auto_renew = false
  tags       = {}
}

resource "azurerm_monitor_autoscale_setting" "autoscalesettings_Default1_Default_Web_WestUS" {
  name                = var.autoscalesettings_Default1_Default_Web_WestUS_name
  location            = var.location_east_us
  resource_group_name = azurerm_resource_group.main.name
  target_resource_id  = azurerm_app_service_plan.serverfarms_Default1.id
  enabled             = true

  profile {
    name = "Default"

    capacity {
      default = 1
      minimum = 1
      maximum = 10
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_app_service_plan.serverfarms_Default1.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT10M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 60
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_app_service_plan.serverfarms_Default1.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT10M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }

  notification {
    email {
      send_to_subscription_administrator    = true
      send_to_subscription_co_administrator = true
      custom_emails                         = []
    }
  }
}


resource "azurerm_dns_a_record" "a_record_root" {
  name                = "@"
  zone_name           = azurerm_dns_zone.dnszones_timmyreilly_com.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 3600

  target_resource_id = "${var.profiles_prodFrontDoor_externalid}/afdendpoints/t-home"
}

resource "azurerm_dns_cname_record" "cname_record_moolah" {
  name                = "moolah"
  zone_name           = azurerm_dns_zone.dnszones_timmyreilly_com.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 3600
  record              = "t-home-fjf7fzftb4ata8ck.z03.azurefd.net"
}

resource "azurerm_dns_txt_record" "txt_record_dnsauth" {
  name                = "_dnsauth"
  zone_name           = azurerm_dns_zone.dnszones_timmyreilly_com.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 3600
  records             = ["9069xkffqc04frt0lhc76c517p4lrlqn"]
}

resource "azurerm_dns_txt_record" "txt_record_dnsauth_moolah" {
  name                = "_dnsauth.moolah"
  zone_name           = azurerm_dns_zone.dnszones_timmyreilly_com.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 3600
  records             = ["8c4d3jptr1wv6vjgfb614j9sy0pyzbr6"]
}



/*
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