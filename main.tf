#List provider 
provider "azurerm" {
    features {}
}

#List existing resource group
data "azurerm_resource_group" "rg" {
    name = "name_of_your_rg"
}

#configure vnet
resource "azurerm_virtual_network" "rg_vnet" {
    name = "test-vnet" 
    address_space = ["10.0.0.0/16"] #It represents the overall range of IP addresses that can be used within the virtual network.
    location = data.azurerm_resource_group.rg.location
    resource_group_name = data.azurerm_resource_group.rg.name
}

#configure subnet
resource "azurerm_subnet" "rg_subnet" {
    name = "test-subnet"
    resource_group_name = data.azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.rg_vnet.name
    address_prefixes = ["10.0.2.0/24"]
}

#configure public ip
resource "azurerm_public_ip" "rg_public_ip" {
    name = "test-public-ip"
    location            = data.azurerm_resource_group.rg.location
    resource_group_name = data.azurerm_resource_group.rg.name
    allocation_method   = "Dynamic"
}

#configure nic
resource "azurerm_network_interface" "rg_nic" {
    name = "test-nic"
    location = data.azurerm_resource_group.rg.location
    resource_group_name = data.azurerm_resource_group.rg.name

    ip_configuration {
        name = "test-ip"
        subnet_id = azurerm_subnet.rg_subnet.id 
        public_ip_address_id = azurerm_public_ip.rg_public_ip.id
        private_ip_address_allocation = "Static"
        private_ip_address = "10.0.2.5"
    }
}

#configure azure virtual machine
resource "azurerm_linux_virtual_machine" "rg_vm" {
    name = "test-vm"
    location = data.azurerm_resource_group.rg.location
    resource_group_name = data.azurerm_resource_group.rg.name
    size = "Standard_B1s"
    admin_username = "ubuntu"

    network_interface_ids = [azurerm_network_interface.rg_nic.id]
    disable_password_authentication = "false"
    admin_password = "itachi#123"

    os_disk {
        caching = "ReadWrite"
        storage_account_type = "Standard_LRS"
        disk_size_gb = 32
    }

    source_image_reference {
        publisher = "Canonical"
        offer = "0001-com-ubuntu-server-jammy"
        sku = "22_04-lts"
        version = "latest"
    }
}

resource "azurerm_network_security_group" "rg_nsg" {
  name                = "test-nsg"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "rg_nsg_association" {
  subnet_id                 = azurerm_subnet.rg_subnet.id
  network_security_group_id = azurerm_network_security_group.rg_nsg.id
}
