terraform {
    backend "azurerm" {
      key  = "preprovisioning.terraform.tfstate"
  }
}