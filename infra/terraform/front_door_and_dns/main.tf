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
resource "azurerm_cdn_frontdoor_origin_group" "storage_origin_group" {
  name                      = "storageorigingroupb"
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


data "azurerm_storage_account" "storage" {
  name                = "webstorage1february"
  resource_group_name = "WebHome1"
}

resource "azurerm_cdn_frontdoor_origin" "staticwebappstorage" {
  name                          = "staticwebappstoregeb"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.storage_origin_group.id
  enabled                       = true

  certificate_name_check_enabled = true

  host_name          = data.azurerm_storage_account.storage.primary_web_host
  http_port          = 80
  https_port         = 443
  origin_host_header = data.azurerm_storage_account.storage.primary_web_host
  priority           = 1
  weight             = 1
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


  cdn_frontdoor_custom_domain_ids = [azurerm_cdn_frontdoor_custom_domain.moolah_timmyreilly_com.id]
  link_to_default_domain          = false

  cache {
    query_string_caching_behavior = "IgnoreSpecifiedQueryStrings"
    query_strings                 = ["account", "settings"]
    compression_enabled           = true
    content_types_to_compress     = ["text/html", "text/javascript", "text/xml"]
  }
}

resource "azurerm_cdn_frontdoor_rule_set" "beginner_rule_set" {
  name                     = "BeginnerRuleSet"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.prodFrontDoor.id
}



# DNS CNAME Record for www.timmyreilly.com pointing to Front Door Endpoint
resource "azurerm_dns_cname_record" "cname_record_www" {
  name                = "www"
  zone_name           = azurerm_dns_zone.dnszones_timmyreilly_com.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 300
  record              = azurerm_cdn_frontdoor_endpoint.afd_endpoint.host_name
}




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

