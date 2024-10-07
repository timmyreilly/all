# /*
# Creates: 
# - ADO Service Connection 
# - Application Insights 
# - Key Vault
# - Resource Group 
# */
provider "azurerm" {
  version         = "=2.21.0"
  subscription_id = var.subscription_id
  features{}
}

#Configure Azure AD provider to point to SP specified through variables.tf 
provider "azuread" {
  version = "~>0.11.0"
  alias           = "serviceprincipal_ad"
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

#Configure azuredevops provider to point to ADO specified instance
provider "azuredevops" {
  version = ">= 0.0.1"
  personal_access_token = var.service_connection_pat
  org_service_url = var.ado_org_service_url
}

data "azuread_service_principal" "serviceprincipal" {
  provider       = azuread.serviceprincipal_ad
  application_id = var.client_id
}

#Create resource group for web resources
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-core-rg"
  location = var.location
}

#Import azuredevops project via 
data "azuredevops_project" "main" {
  project_name = var.ado_project_name
}

#Initialize local variables for azuredevops project_id and web resource naming conventions
locals {
  project_id = data.azuredevops_project.main.id

}

#If run locally this will add the specific user to the key vault access policy
data "azurerm_client_config" "current" {
}

#Create key vault
resource "azurerm_key_vault" "main" {
  name                            = "${var.prefix}corepipelinekv"
  location                        = azurerm_resource_group.main.location
  resource_group_name             = azurerm_resource_group.main.name
  enabled_for_disk_encryption     = true
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  tenant_id                       = var.tenant_id

  sku_name                    = "standard"

  #Add access policy for current user
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "create",
      "get",
    ]

    secret_permissions = [
      "set",
      "get",
      "delete",
      "list"
    ]
  }

  #Add access policy for service principal
  access_policy {
    tenant_id = var.tenant_id
    object_id = data.azuread_service_principal.serviceprincipal.object_id

    secret_permissions = [
      "list",
      "get",
    ]
  }
}

#Create service connection
resource "azuredevops_serviceendpoint_azurerm" "endpointazure" {
  project_id                = local.project_id 
  service_endpoint_name     = "serviceconnection-${var.prefix}"
  azurerm_spn_tenantid      = var.tenant_id
  azurerm_subscription_id   = var.subscription_id
  azurerm_subscription_name = var.subscription_name
  credentials {
    serviceprincipalid  = var.client_id
    serviceprincipalkey = var.client_secret
  }
}

#Create application insights
resource "azurerm_application_insights" "main" {
  name                = "${var.prefix}-appinsights"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
}


resource "azuredevops_variable_group" "variablegroup" {
  project_id   = local.project_id
  name         = "pipeline-service-connection"
  description  = "service connection for pipelines"
  allow_access = true

  variable {
    name      = "azureSubscriptionEndpoint"
    value     = azuredevops_serviceendpoint_azurerm.endpointazure.service_endpoint_name
    is_secret = false
  }
}