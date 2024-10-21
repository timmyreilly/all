variable "subscription_id" {
  description = "Subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location_east_us" {
  default     = "East US"
  description = "Location for East US resources"
}

variable "location_west_us" {
  default     = "West US"
  description = "Location for West US resources"
}

# SecureString Parameters
variable "domains_timmyreilly_com_email" {
  type      = string
  sensitive = true
}

variable "domains_timmyreilly_com_nameFirst" {
  type      = string
  sensitive = true
}

variable "domains_timmyreilly_com_nameLast" {
  type      = string
  sensitive = true
}

variable "domains_timmyreilly_com_phone" {
  type      = string
  sensitive = true
}

variable "domains_timmyreilly_com_email_1" {
  type      = string
  sensitive = true
}

variable "domains_timmyreilly_com_nameFirst_1" {
  type      = string
  sensitive = true
}

variable "domains_timmyreilly_com_nameLast_1" {
  type      = string
  sensitive = true
}

variable "domains_timmyreilly_com_phone_1" {
  type      = string
  sensitive = true
}

variable "domains_timmyreilly_com_email_2" {
  type      = string
  sensitive = true
}

variable "domains_timmyreilly_com_nameFirst_2" {
  type      = string
  sensitive = true
}

variable "domains_timmyreilly_com_nameLast_2" {
  type      = string
  sensitive = true
}

variable "domains_timmyreilly_com_phone_2" {
  type      = string
  sensitive = true
}

variable "domains_timmyreilly_com_email_3" {
  type      = string
  sensitive = true
}

variable "domains_timmyreilly_com_nameFirst_3" {
  type      = string
  sensitive = true
}

variable "domains_timmyreilly_com_nameLast_3" {
  type      = string
  sensitive = true
}

variable "domains_timmyreilly_com_phone_3" {
  type      = string
  sensitive = true
}

# Backup Parameters
variable "backups" {
  description = "List of backup configurations"
  type = list(object({
    id                  = string
    storage_account_url = string
    overwrite           = bool
    blob_name           = string
  }))
}

# String Parameters with Defaults
variable "sites_timmyreilly_name" {
  type        = string
  default     = "timmyreilly"
  description = "Name of the timmyreilly site"
}

variable "sites_FinalProtocol_name" {
  type        = string
  default     = "FinalProtocol"
  description = "Name of the FinalProtocol site"
}

variable "serverfarms_Default1_name" {
  type        = string
  default     = "Default1"
  description = "Name of the Default1 App Service Plan"
}

variable "components_timmyreilly_name" {
  type        = string
  default     = "timmyreilly"
  description = "Name of the Application Insights component"
}

variable "dnszones_timmyreilly_com_name" {
  type        = string
  default     = "timmyreilly.com"
  description = "DNS zone name"
}

variable "domains_timmyreilly_com_name" {
  type        = string
  default     = "timmyreilly.com"
  description = "Domain name"
}

variable "autoscalesettings_Default1_Default_Web_WestUS_name" {
  type        = string
  default     = "Default1-Default-Web-WestUS"
  description = "Name of the autoscale setting"
}

variable "profiles_prodFrontDoor_externalid" {
  type        = string
  default     = "/subscriptions/e335a81a-26bb-48bb-b4fe-63a9754e111a/resourceGroups/WebHome1/providers/Microsoft.Cdn/profiles/prodFrontDoor"
  description = "External ID for the Front Door profile"
}
