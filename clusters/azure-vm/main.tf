provider "azurerm" {
  version = "=2.0.0"
  features {}
}

resource "azurerm_resource_group" "faastest" {
  name     = "faastest-resources"
  location = var.location
}

resource "azurerm_virtual_network" "faastest" {
  name                = "faastest-network"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.faastest.location
  resource_group_name = azurerm_resource_group.faastest.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.faastest.name
  virtual_network_name = azurerm_virtual_network.faastest.name
  address_prefix       = "10.1.1.0/24"
}

resource "azurerm_public_ip" "faastest_ip" {
  name                = "faastest-ip"
  resource_group_name = azurerm_resource_group.faastest.name
  location            = azurerm_resource_group.faastest.location
  allocation_method   = "Dynamic"
}

data "azurerm_public_ip" "faastest_ip" {
  name                = azurerm_public_ip.faastest_ip.name
  resource_group_name = azurerm_resource_group.faastest.name
  depends_on          = [azurerm_linux_virtual_machine.faastest]
}

resource "azurerm_network_interface" "faastest" {
  name                = "faastest-nic1"
  resource_group_name = azurerm_resource_group.faastest.name
  location            = azurerm_resource_group.faastest.location

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.faastest_ip.id
  }
}

resource "azurerm_network_interface" "faastest_internal" {
  name                      = "faastest-nic2"
  resource_group_name       = azurerm_resource_group.faastest.name
  location                  = azurerm_resource_group.faastest.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_security_group" "faastest_vm" {
  name                = "faastest-vm-sg"
  location            = azurerm_resource_group.faastest.location
  resource_group_name = azurerm_resource_group.faastest.name

  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "22"
    source_address_prefix      = "*"
    destination_port_range     = "22"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "faastest" {
  network_interface_id      = azurerm_network_interface.faastest_internal.id
  network_security_group_id = azurerm_network_security_group.faastest_vm.id
}

resource "azurerm_linux_virtual_machine" "faastest" {
  name                = "faastest-vm"
  resource_group_name = azurerm_resource_group.faastest.name
  location            = azurerm_resource_group.faastest.location
  size                = var.vm_size
  admin_username      = "adminuser"
  
  admin_ssh_key {
    username = "adminuser"
    public_key = file(var.public_key_path)
  }

  network_interface_ids = [
    azurerm_network_interface.faastest.id,
    azurerm_network_interface.faastest_internal.id,
  ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}

resource "azurerm_virtual_machine_extension" "docker_extension" {
  name                       = "faastest-docker-extension"
  virtual_machine_id         = azurerm_linux_virtual_machine.faastest.id
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "DockerExtension"
  type_handler_version       = "1.2"
  auto_upgrade_minor_version = "true"
  settings                   = "{}"
}

##################################################

output "vm_ip_address" {
  value = data.azurerm_public_ip.faastest_ip.ip_address
}
