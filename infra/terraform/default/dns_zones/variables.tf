variable "subscription_id" {
  description = "Subscription ID"
  type        = string
}

variable "prefix" {
  description = "Prefix for naming convention ex 'dev'"
  type        = string
}

variable "resource_group_name" {
  description = "Name of Preexisting Resource Group"
  type        = string
}

variable "resource_group_location" {
  description = "Name of Preexisting Resource Group Location"
  type        = string
}

variable "tag_module_id" { 
    description = "id to track state of module deployment"
    type        = string 
    default =  "1" 
}