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

locals {
  name_prefix        = "${var.project_name}-${var.environment}"
  custom_data_base64 = base64encode(var.custom_data)
}

# Grupo de recursos principal que contendrá todos los recursos del entorno de desarrollo.
resource "azurerm_resource_group" "rg" {
  name     = "${local.name_prefix}-rg"
  location = var.azure_region

  tags = var.common_tags
}

# Red virtual con un espacio de direcciones privado amplio para futuros servicios.
resource "azurerm_virtual_network" "vnet" {
  name                = "${local.name_prefix}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.vnet_address_space

  tags = var.common_tags
}

# Subred donde se conectará la interfaz de red de la VM.
resource "azurerm_subnet" "subnet" {
  name                 = "${local.name_prefix}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_address_prefixes
}

# IP pública estática para exponer el servidor web de forma predecible.
resource "azurerm_public_ip" "pip" {
  name                = "${local.name_prefix}-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = var.public_ip_allocation_method
  sku                 = var.public_ip_sku

  tags = var.common_tags
}

# Grupo de seguridad de red con la regla mínima necesaria para HTTP.
# Se agrega una segunda regla para SSH (puerto 22) documentada explícitamente como
# excepción de administración, necesaria para la validación manual indicada en la guía.
resource "azurerm_network_security_group" "nsg" {
  name                = "${local.name_prefix}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  dynamic "security_rule" {
    for_each = var.nsg_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }

  tags = var.common_tags
}

# Interfaz de red de la VM. Vincula la subred y la IP pública.
resource "azurerm_network_interface" "nic" {
  name                = "${local.name_prefix}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = var.nic_private_ip_address_allocation
    public_ip_address_id          = azurerm_public_ip.pip.id
  }

  tags = var.common_tags
}

# Asocia el NSG a la interfaz de red de la VM.
resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Máquina virtual Ubuntu Server 22.04 LTS (gen2) con autenticación SSH únicamente.
resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "${local.name_prefix}-vm"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = var.tamano_vm
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.nic.id]
  custom_data                     = local.custom_data_base64

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    name                 = var.os_disk_name != "" ? var.os_disk_name : "${local.name_prefix}-osdisk"
    caching              = var.os_disk_caching
    storage_account_type = var.os_disk_storage_account_type
  }

  source_image_reference {
    publisher = var.os_image.publisher
    offer     = var.os_image.offer
    sku       = var.os_image.sku
    version   = var.os_image.version
  }

  tags = var.common_tags
}
