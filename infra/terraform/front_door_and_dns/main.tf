# Specify the required AzureRM provider version
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

# Create Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location_west_us
}

# Create DNS Zone
resource "azurerm_dns_zone" "dnszones_timmyreilly_com" {
  name                = var.dnszones_timmyreilly_com_name
  resource_group_name = azurerm_resource_group.main.name
}

# Create Azure Front Door Profile
resource "azurerm_cdn_frontdoor_profile" "prodFrontDoor" {
  name                = var.profiles_prodFrontDoor_name
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Standard_AzureFrontDoor" # Use "Premium" or "Standard"

  tags = {
    env = "prod"
  }
}

# Create Azure Front Door Endpoint
resource "azurerm_cdn_frontdoor_endpoint" "trei_home" {
  name                      = "trei-home"
  cdn_frontdoor_profile_id  = azurerm_cdn_frontdoor_profile.prodFrontDoor.id
  enabled                   = true
}

resource "azurerm_cdn_frontdoor_endpoint" "afd_endpoint" {
  name                = "timmyreilly-afd-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.prodFrontDoor.id
  enabled                   = true
}



resource "azurerm_cdn_frontdoor_custom_domain" "root_custom_domain" {
  name                     = "timmyreilly-com"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.prodFrontDoor.id
  dns_zone_id              = azurerm_dns_zone.dnszones_timmyreilly_com.id
  host_name                = join(".", ["timmyreilly", azurerm_dns_zone.dnszones_timmyreilly_com.name])

  tls {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}


resource "azurerm_cdn_frontdoor_custom_domain" "moolah_timmyreilly_com" {
  name                      = "moolah-timmyreilly-com"
  cdn_frontdoor_profile_id  = azurerm_cdn_frontdoor_profile.prodFrontDoor.id
  host_name                 = "moolahb.timmyreilly.com"

  tls {
    certificate_type = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}

# # Create DNS TXT Records for Domain Validation
# # Example for iot.timmyreilly.com
resource "azurerm_dns_txt_record" "moolah_timmyreilly_com_validation" {
  name                = azurerm_cdn_frontdoor_custom_domain.moolah_timmyreilly_com.name
  zone_name           = azurerm_dns_zone.dnszones_timmyreilly_com.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 3600

  record {
    value = azurerm_cdn_frontdoor_custom_domain.moolah_timmyreilly_com.validation_token
  }
}


# # Create Origin Groups
resource "azurerm_cdn_frontdoor_origin_group" "default_origin_group" {
  name                      = "default-origin-group"
  cdn_frontdoor_profile_id  = azurerm_cdn_frontdoor_profile.prodFrontDoor.id

  load_balancing {
    sample_size                     = 4
    successful_samples_required     = 3
  }

  health_probe {
    path                    = "/"
    protocol                = "Http"
    interval_in_seconds     = 100
    request_type            = "HEAD"
  }
}

resource "azurerm_cdn_frontdoor_origin_group" "storage_origin_group" {
  name                      = "storageorigingroup"
  cdn_frontdoor_profile_id  = azurerm_cdn_frontdoor_profile.prodFrontDoor.id

  load_balancing {
    sample_size                     = 4
    successful_samples_required     = 3
  }

  health_probe {
    path                    = "/"
    protocol                = "Http"
    interval_in_seconds     = 255
    request_type            = "HEAD"
  }
}

resource "azurerm_cdn_frontdoor_origin_group" "example" {
  name                = "storage-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.prodFrontDoor.id

  load_balancing {
    additional_latency_in_milliseconds = 0
    sample_size                        = 16
    successful_samples_required        = 3
  }
}

data "azurerm_storage_account" "storage" {
  name                = "webstorage1february"
  resource_group_name = "WebHome1"
}

resource "azurerm_cdn_frontdoor_profile" "afd_profile" {
  name                = "beginner-profile"
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Standard_AzureFrontDoor"
}

resource "azurerm_cdn_frontdoor_origin" "afd_origin" {
  name                          = "storage-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.storage_origin_group.id
  enabled                       = true

  certificate_name_check_enabled = false

  host_name          = data.azurerm_storage_account.storage.primary_web_host
  http_port          = 80
  https_port         = 443
  origin_host_header = data.azurerm_storage_account.storage.primary_web_host
  priority           = 1
  weight             = 1
}



resource "azurerm_cdn_frontdoor_origin" "default_origin" {
  name                          = "default-origin"
  host_name                     = "webstorage1february.blob.core.windows.net"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.default_origin_group.id
  http_port                     = 80
  https_port                    = 443
  origin_host_header            = "webstorage1february.web.core.windows.net"
  priority                      = 1
  weight                        = 1000
  enabled                       = true
  certificate_name_check_enabled = true
}

resource "azurerm_cdn_frontdoor_origin" "staticwebappstorage" {
  name                          = "staticwebappstorage"
  host_name                     = "webstorage1february.z5.web.core.windows.net"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.storage_origin_group.id
  http_port                     = 80
  https_port                    = 443
  origin_host_header            = "webstorage1february.z5.web.core.windows.net"
  priority                      = 1
  weight                        = 1000
  enabled                       = true
  certificate_name_check_enabled = true
}

# # Create Routes
resource "azurerm_cdn_frontdoor_route" "default_route" {
  name                          = "default-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.trei_home.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.storage_origin_group.id
  supported_protocols           = ["Http", "Https"]
  patterns_to_match             = ["/*"]
  forwarding_protocol           = "MatchRequest"
  https_redirect_enabled        = true
  cdn_frontdoor_origin_ids      = []
}

resource "azurerm_cdn_frontdoor_rule_set" "beginner_rule_set" {
  name                     = "BeginnerRuleSet"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.afd_profile.id
}

# Route to Redirect timmyreilly.com to www.timmyreilly.com
resource "azurerm_cdn_frontdoor_route" "afd_route_www" {
  name                          = "route-www"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.trei_home.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.storage_origin_group.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.afd_origin.id]
  cdn_frontdoor_rule_set_ids    = [azurerm_cdn_frontdoor_rule_set.beginner_rule_set.id]
  enabled                       = true

  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]

  cdn_frontdoor_custom_domain_ids = [azurerm_cdn_frontdoor_custom_domain.moolah_timmyreilly_com.id, azurerm_cdn_frontdoor_custom_domain.root_custom_domain.id]
  link_to_default_domain          = false

  cache {
    query_string_caching_behavior = "IgnoreSpecifiedQueryStrings"
    query_strings                 = ["account", "settings"]
    compression_enabled           = true
    content_types_to_compress     = ["text/html", "text/javascript", "text/xml"]
  }
}


# DNS CNAME Record for www.timmyreilly.com pointing to Front Door Endpoint
resource "azurerm_dns_cname_record" "cname_record_www" {
  name                = "www"
  zone_name           = azurerm_dns_zone.dnszones_timmyreilly_com.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 300
  record              = azurerm_cdn_frontdoor_endpoint.afd_endpoint.host_name
}

# DNS Alias A Record for timmyreilly.com pointing to Front Door Custom Domain
# resource "azurerm_dns_a_record" "a_record_root_b" {
#   name                = "@"
#   zone_name           = azurerm_dns_zone.dnszones_timmyreilly_com.name
#   resource_group_name = azurerm_resource_group.main.name

#   ttl = 300

#   target_resource_id = azurerm_cdn_frontdoor_custom_domain.root_custom_domain.id
# }


# # Create DNS Records
resource "azurerm_dns_a_record" "a_record_root" {
  name                = "@"
  zone_name           = azurerm_dns_zone.dnszones_timmyreilly_com.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 3600

  target_resource_id = azurerm_cdn_frontdoor_endpoint.trei_home.id
}

resource "azurerm_dns_cname_record" "cname_record_moolah" {
  name                = "moolah"
  zone_name           = azurerm_dns_zone.dnszones_timmyreilly_com.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 3600
  record              = azurerm_cdn_frontdoor_endpoint.trei_home.host_name
}


### Archive of previous resources

# # Create App Service Domain
# resource "azurerm_app_service_domain" "domains_timmyreilly_com" {
#   name                = var.domains_timmyreilly_com_name
#   resource_group_name = azurerm_resource_group.main.name
#   location            = "global"

#   management_group_id = azurerm_dns_zone.dnszones_timmyreilly_com.id

#   contact {
#     admin {
#       email       = var.domains_timmyreilly_com_email
#       first_name  = var.domains_timmyreilly_com_nameFirst
#       last_name   = var.domains_timmyreilly_com_nameLast
#       phone       = var.domains_timmyreilly_com_phone
#       address1    = "123 Main St"
#       city        = "Seattle"
#       state       = "WA"
#       postal_code = "98101"
#       country     = "US"
#     }
#     billing {
#       email       = var.domains_timmyreilly_com_email_1
#       first_name  = var.domains_timmyreilly_com_nameFirst_1
#       last_name   = var.domains_timmyreilly_com_nameLast_1
#       phone       = var.domains_timmyreilly_com_phone_1
#       address1    = "123 Main St"
#       city        = "Seattle"
#       state       = "WA"
#       postal_code = "98101"
#       country     = "US"
#     }
#     registrant {
#       email       = var.domains_timmyreilly_com_email_2
#       first_name  = var.domains_timmyreilly_com_nameFirst_2
#       last_name   = var.domains_timmyreilly_com_nameLast_2
#       phone       = var.domains_timmyreilly_com_phone_2
#       address1    = "123 Main St"
#       city        = "Seattle"
#       state       = "WA"
#       postal_code = "98101"
#       country     = "US"
#     }
#     tech {
#       email       = var.domains_timmyreilly_com_email_3
#       first_name  = var.domains_timmyreilly_com_nameFirst_3
#       last_name   = var.domains_timmyreilly_com_nameLast_3
#       phone       = var.domains_timmyreilly_com_phone_3
#       address1    = "123 Main St"
#       city        = "Seattle"
#       state       = "WA"
#       postal_code = "98101"
#       country     = "US"
#     }
#   }

#   auto_renew = false
#   tags       = {}
# }


# resource "azurerm_cdn_frontdoor_custom_domain" "www_custom_domain" {
#   name                     = "www-timmyreilly-com"
#   resource_group_name      = azurerm_resource_group.main.name
#   profile_name             = azurerm_cdn_frontdoor_profile.prodFrontDoor.name
#   host_name                = "www.timmyreilly.com"
#   dns_zone_id              = azurerm_dns_zone.dnszones_timmyreilly_com.id

#   # Enable HTTPS with Azure-managed certificates
#   tls {
#     certificate_type    = "ManagedCertificate"
#     minimum_tls_version = "TLS12"
#   }
# }

# resource "azurerm_cdn_frontdoor_custom_domain" "root_custom_domain" {
#   name                     = "timmyreilly-com"
#   resource_group_name      = azurerm_resource_group.main.name
#   profile_name             = azurerm_cdn_frontdoor_profile.prodFrontDoor.name
#   host_name                = "timmyreilly.com"
#   dns_zone_id              = azurerm_dns_zone.dnszones_timmyreilly_com.id

#   # Enable HTTPS with Azure-managed certificates
#   tls {
#     certificate_type    = "ManagedCertificate"
#     minimum_tls_version = "TLS12"
#   }
# }


# # Create Azure Front Door Custom Domains
# resource "azurerm_cdn_frontdoor_custom_domain" "iot_timmyreilly_com" {
#   name                      = "iot-timmyreilly-com"
# #   cdn_frontdoor_profile_id  = azurerm_cdn_frontdoor_profile.prodFrontDoor.id
#   host_name                 = "iot.timmyreilly.com"

#   tls {
#     certificate_type = "ManagedCertificate"
#     minimum_tls_version = "TLS1_2"
#   }
# }

# resource "azurerm_cdn_frontdoor_custom_domain" "vpn_timmyreilly_com" {
#   name                      = "vpn-timmyreilly-com-0897"
# #   cdn_frontdoor_profile_id  = azurerm_cdn_frontdoor_profile.prodFrontDoor.id
#   host_name                 = "vpn.timmyreilly.com"

#   tls {
#     certificate_type = "ManagedCertificate"
#     minimum_tls_version = "TLS1_2"
#   }
# }








# resource "azurerm_cdn_frontdoor_origin_group" "afd_origin_group" {
#   name                = "storage-origin-group"
#   profile_name        = azurerm_cdn_frontdoor_profile.prodFrontDoor.name
#   resource_group_name = azurerm_resource_group.main.name

#   health_probe_enabled = true
#   health_probe_method  = "HEAD"
#   health_probe_path    = "/"
#   probe_request_type   = "Https"
# }

# resource "azurerm_cdn_frontdoor_origin_group" "timmyreillyazurewebsitesnet" {
#   name                      = "timmyreillyazurewebsitesnet"
#   cdn_frontdoor_profile_id  = azurerm_cdn_frontdoor_profile.prodFrontDoor.id

#   load_balancing {
#     # additional_latency_milliseconds = 50
#     sample_size                     = 4
#     successful_samples_required     = 3
#   }

#   health_probe {
#     path                    = "/"
#     protocol                = "Http"
#     interval_in_seconds     = 100
#     request_type            = "HEAD"
#   }
# }

# # Create Origins
# resource "azurerm_cdn_frontdoor_origin" "azurewebsitestimmyreilly" {
#   name                          = "azurewebsitestimmyreilly"
#   host_name                     = "timmyreilly.azurewebsites.net"
#   cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.timmyreillyazurewebsitesnet.id
#   http_port                     = 80
#   https_port                    = 443
#   origin_host_header            = "timmyreilly.azurewebsites.net"
#   priority                      = 1
#   weight                        = 1000
#   enabled                       = true
#   certificate_name_check_enabled = true
# }




# resource "azurerm_cdn_frontdoor_origin" "afd_origin" {
#   name                = "storage-origin"
#   profile_name        = azurerm_cdn_frontdoor_profile.afd_profile.name
#   # resource_group_name = azurerm_resource_group.rg.name
#   # origin_group_name   = azurerm_cdn_frontdoor_origin_group.afd_origin_group.name

#   host_name          = data.azurerm_storage_account.storage.primary_web_host
#   origin_host_header = data.azurerm_storage_account.storage.primary_web_host
#   http_port          = 80
#   https_port         = 443
#   priority           = 1
#   weight             = 1000
#   enabled            = true
# }






# resource "azurerm_cdn_frontdoor_route" "private_network_routing" {
#   name                          = "private-network-routing"
#   cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.trei_home.id
#   cdn_frontdoor_profile_id      = azurerm_cdn_frontdoor_profile.prodFrontDoor.id
#   cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.default_origin_group.id
#   supported_protocols           = ["Http", "Https"]
#   patterns_to_match             = ["/*"]
#   forwarding_protocol           = "MatchRequest"
#   https_redirect_enabled        = true
#   custom_domains                = [azurerm_cdn_frontdoor_custom_domain.vpn_timmyreilly_com.id]
#   # enable_caching                = false
# }


# resource "azurerm_dns_txt_record" "txt_record_dnsauth" {
#   name                = "_dnsauth"
#   zone_name           = azurerm_dns_zone.dnszones_timmyreilly_com.name
#   resource_group_name = azurerm_resource_group.main.name
#   ttl                 = 3600

#   record {
#     value = "9069xkffqc04frt0lhc76c517p4lrlqn"
#   }
# }

# resource "azurerm_dns_txt_record" "txt_record_dnsauth_moolah" {
#   name                = "_dnsauth.moolah"
#   zone_name           = azurerm_dns_zone.dnszones_timmyreilly_com.name
#   resource_group_name = azurerm_resource_group.main.name
#   ttl                 = 3600

#   record {
#     value = "8c4d3jptr1wv6vjgfb614j9sy0pyzbr6"
#   }
# }

# # Optional: Include Autoscale Settings if you have an App Service Plan
# # Note: Ensure that the App Service Plan resource exists
# # resource "azurerm_app_service_plan" "serverfarms_Default1" {
# #   name                = var.serverfarms_Default1_name
# #   location            = var.location_west_us
# #   resource_group_name = azurerm_resource_group.main.name
# #   kind                = "Windows"
# #   reserved            = false
# #   per_site_scaling    = false
# #
# #   sku {
# #     tier     = "Standard"
# #     size     = "S1"
# #     capacity = 1
# #   }
# # }
# #
# # resource "azurerm_monitor_autoscale_setting" "autoscalesettings_Default1_Default_Web_WestUS" {
# #   name                = var.autoscalesettings_Default1_Default_Web_WestUS_name
# #   location            = var.location_east_us
# #   resource_group_name = azurerm_resource_group.main.name
# #   target_resource_id  = azurerm_app_service_plan.serverfarms_Default1.id
# #   enabled             = true
# #
# #   profile {
# #     name = "Default"
# #
# #     capacity {
# #       default = 1
# #       minimum = 1
# #       maximum = 10
# #     }
# #
# #     rule {
# #       metric_trigger {
# #         metric_name        = "CpuPercentage"
# #         metric_resource_id = azurerm_app_service_plan.serverfarms_Default1.id
# #         time_grain         = "PT1M"
# #         statistic          = "Average"
# #         time_window        = "PT10M"
# #         time_aggregation   = "Average"
# #         operator           = "GreaterThan"
# #         threshold          = 60
# #       }
# #
# #       scale_action {
# #         direction = "Increase"
# #         type      = "ChangeCount"
# #         value     = "1"
# #         cooldown  = "PT5M"
# #       }
# #     }
# #
# #     rule {
# #       metric_trigger {
# #         metric_name        = "CpuPercentage"
# #         metric_resource_id = azurerm_app_service_plan.serverfarms_Default1.id
# #         time_grain         = "PT1M"
# #         statistic          = "Average"
# #         time_window        = "PT10M"
# #         time_aggregation   = "Average"
# #         operator           = "LessThan"
# #         threshold          = 25
# #       }
# #
# #       scale_action {
# #         direction = "Decrease"
# #         type      = "ChangeCount"
# #         value     = "1"
# #         cooldown  = "PT5M"
# #       }
# #     }
# #   }
# #
# #   notification {
# #     email {
# #       send_to_subscription_administrator    = true
# #       send_to_subscription_co_administrator = true
# #       custom_emails                         = []
# #     }
# #   }
# # }
