variable "subscription_id" {
  description = "Subscription ID"
  type        = string
}

variable "unique" {
  description = "A unique identifier for naming resources."
  default     = "che2"
}

variable "location" {
  description = "The Azure region where resources will be deployed."
  default     = "westus2"
}

variable "admin_username" {
  description = "Admin username for the virtual machine."
  default     = "che2-user"
}

variable "admin_password" {
  description = "Admin password for the virtual machine."
  sensitive   = true
}

variable "vm_size" {
  description = "Size of the virtual machine."
  default     = "Standard_DS1_v2"
}

variable "vm_image" {
  description = "The image used for the virtual machine."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-21h2-pro"
    version   = "latest"
  }
}

variable "tag_module_id" { 
    description = "id to track state of module deployment"
    type        = string 
    default     =  "dev123" 
}

variable "tag_module_type" {
  description = "type of module represented" 
  type        = string 
  default     = "hub_and_spoke" 
}