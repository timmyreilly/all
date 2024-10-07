/*
Creates: 
- Core Virtual Network 
- Core Default Subnet
- Ubuntu VM to be used as Azure DevOps Build Agent  

*/


provider "azurerm" {
  version         = "=2.0.0"
  subscription_id = var.subscription_id
  features {}
}

resource "azurerm_subnet" "default" {
  name                 = "default"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefix       = "10.0.2.0/24"
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