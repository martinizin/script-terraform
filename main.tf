terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Grupo de recursos principal que contendrá todos los recursos del entorno de desarrollo.
resource "azurerm_resource_group" "rg" {
  name     = "techustart-dev-rg"
  location = var.azure_region

  tags = {
    environment = "dev"
    project     = "techustart"
  }
}

# Red virtual con un espacio de direcciones privado amplio para futuros servicios.
resource "azurerm_virtual_network" "vnet" {
  name                = "techustart-dev-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "dev"
    project     = "techustart"
  }
}

# Subred donde se conectará la interfaz de red de la VM.
resource "azurerm_subnet" "subnet" {
  name                 = "techustart-dev-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# IP pública estática para exponer el servidor web de forma predecible.
resource "azurerm_public_ip" "pip" {
  name                = "techustart-dev-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = "dev"
    project     = "techustart"
  }
}

# Grupo de seguridad de red con la regla mínima necesaria para HTTP.
# Se agrega una segunda regla para SSH (puerto 22) documentada explícitamente como
# excepción de administración, necesaria para la validación manual indicada en la guía.
resource "azurerm_network_security_group" "nsg" {
  name                = "techustart-dev-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "dev"
    project     = "techustart"
  }
}

# Interfaz de red de la VM. Vincula la subred y la IP pública.
resource "azurerm_network_interface" "nic" {
  name                = "techustart-dev-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }

  tags = {
    environment = "dev"
    project     = "techustart"
  }
}

# Asocia el NSG a la interfaz de red de la VM.
resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Script de bootstrap codificado en Base64: instala Apache2 al arrancar la VM.
# La función try permite validar la configuración aunque la clave SSH aún no exista
# en la máquina donde se ejecuta `terraform validate`.
locals {
  custom_data = base64encode(<<-EOF
#!/bin/bash
apt-get update
apt-get install -y apache2
systemctl enable apache2
systemctl start apache2
EOF
  )

  ssh_public_key = try(
    file(pathexpand("~/.ssh/id_rsa.pub")),
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMr4SqH9vsFxpcQpL332Eq4bfB93ovd2+YePeL0wtGeV placeholder-reemplazar-por-tu-clave-publica"
  )
}

# Máquina virtual Ubuntu Server 22.04 LTS (gen2) con autenticación SSH únicamente.
resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "techustart-dev-vm"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = var.tamano_vm
  admin_username                  = "azureuser"
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.nic.id]
  custom_data                     = local.custom_data

  admin_ssh_key {
    username   = "azureuser"
    public_key = local.ssh_public_key
  }

  os_disk {
    name                 = "techustart-dev-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = {
    environment = "dev"
    project     = "techustart"
  }
}
