terraform {
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
    }
    azuredevops = {
      source = "terraform-providers/azuredevops"
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
  required_version = ">= 0.13"
}
