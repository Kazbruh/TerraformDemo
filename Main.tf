#DR configure to UK West and enable
#Backups - Enable - take at 2AM
#Automanage Production - enable
#Automanage Dev/Test - enable

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.49.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "demo" {
  name     = "Demo"
  location = "UK South"
}

resource "azurerm_virtual_network" "demo" {
  name                = "Demo_Virtual_Network"
  address_space       = ["10.0.2.0/24"]
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
}

# Subnets
resource "azurerm_subnet" "live" {
  name                 = "Live"
  resource_group_name  = azurerm_resource_group.demo.name
  virtual_network_name = azurerm_virtual_network.demo.name
  address_prefixes     = ["10.0.2.0/27"]
}

resource "azurerm_subnet" "test" {
  name                 = "Test"
  resource_group_name  = azurerm_resource_group.demo.name
  virtual_network_name = azurerm_virtual_network.demo.name
  address_prefixes     = ["10.0.2.32/27"]
}

resource "azurerm_subnet" "train" {
  name                 = "Train"
  resource_group_name  = azurerm_resource_group.demo.name
  virtual_network_name = azurerm_virtual_network.demo.name
  address_prefixes     = ["10.0.2.64/27"]
}

# Network Security Group for "Live"
resource "azurerm_network_security_group" "live" {
  name                = "liveNSG"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name

  security_rule {
    name                       = "Allow80Inbound"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow443Inbound"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "test" {
  name                = "testNSG"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name

  security_rule {
    name                       = "Allow80Inbound"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow443Inbound"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "train" {
  name                = "trainNSG"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name

  security_rule {
    name                       = "Allow80Inbound"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow443Inbound"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associating NSGs with subnets
resource "azurerm_subnet_network_security_group_association" "live" {
  subnet_id                 = azurerm_subnet.live.id
  network_security_group_id = azurerm_network_security_group.live.id
}

resource "azurerm_subnet_network_security_group_association" "test" {
  subnet_id                 = azurerm_subnet.test.id
  network_security_group_id = azurerm_network_security_group.test.id
}

resource "azurerm_subnet_network_security_group_association" "train" {
  subnet_id                 = azurerm_subnet.train.id
  network_security_group_id = azurerm_network_security_group.train.id
}

# Network interfaces
resource "azurerm_network_interface" "demo_live" {
  name                = "Demo_NIC_Live"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.live.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "demo_test" {
  name                = "Demo_NIC_Test"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.test.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "demo_train" {
  name                = "Demo_NIC_Train"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.train.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Virtual machines
resource "azurerm_windows_virtual_machine" "demo_live" {
  name                = "DemoAppLive"
  resource_group_name = azurerm_resource_group.demo.name
  location            = azurerm_resource_group.demo.location
  size                = "Standard_B1ls"
  admin_username      = "AdminUser"
  admin_password      = "Welcome123Live"
  network_interface_ids = [
    azurerm_network_interface.demo_live.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter-Core"
    version   = "latest"
  }
}

resource "azurerm_windows_virtual_machine" "demo_test" {
  name                = "DemoAppTest"
  resource_group_name = azurerm_resource_group.demo.name
  location            = azurerm_resource_group.demo.location
  size                = "Standard_B1ls"
  admin_username      = "AdminUser"
  admin_password      = "Welcome123Test"
  network_interface_ids = [
    azurerm_network_interface.demo_test.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter-Core"
    version   = "latest"
  }
}

resource "azurerm_windows_virtual_machine" "demo_train" {
  name                = "DemoAppTrain"
  resource_group_name = azurerm_resource_group.demo.name
  location            = azurerm_resource_group.demo.location
  size                = "Standard_B1ls"
  admin_username      = "AdminUser"
  admin_password      = "Welcome123Train"
  network_interface_ids = [
    azurerm_network_interface.demo_train.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter-Core"
    version   = "latest"
  }
}