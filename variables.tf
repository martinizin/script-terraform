# variables.tf
# Variables de configuración del despliegue de TechUStart.

variable "azure_region" {
  description = "Región de despliegue de los recursos"
  type        = string
  default     = "eastus"
}

variable "tamano_vm" {
  description = "SKU económico/capa gratuita para la VM"
  type        = string
  default     = "Standard_B1s"
}

variable "project_name" {
  description = "Nombre del proyecto, usado como prefijo en los nombres de los recursos"
  type        = string
  default     = "techustart"
}

variable "environment" {
  description = "Ambiente de despliegue (dev, staging, prod, etc.)"
  type        = string
  default     = "dev"
}

variable "common_tags" {
  description = "Tags comunes aplicados a todos los recursos"
  type        = map(string)
  default = {
    environment = "dev"
    project     = "techustart"
  }
}

variable "vnet_address_space" {
  description = "Espacio de direcciones de la red virtual"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefixes" {
  description = "Prefijos de direcciones de la subred"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "public_ip_allocation_method" {
  description = "Método de asignación de la dirección IP pública"
  type        = string
  default     = "Static"
}

variable "public_ip_sku" {
  description = "SKU de la dirección IP pública"
  type        = string
  default     = "Standard"
}

variable "nsg_rules" {
  description = "Lista de reglas de seguridad del grupo de seguridad de red"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = [
    {
      name                       = "AllowHTTP"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
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
  ]
}

variable "nic_private_ip_address_allocation" {
  description = "Método de asignación de la dirección IP privada de la interfaz de red"
  type        = string
  default     = "Dynamic"
}

variable "admin_username" {
  description = "Nombre de usuario administrador de la máquina virtual"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "Clave pública SSH para la autenticación del usuario administrador"
  type        = string
}

variable "os_disk_caching" {
  description = "Tipo de almacenamiento en caché del disco del sistema operativo"
  type        = string
  default     = "ReadWrite"
}

variable "os_disk_storage_account_type" {
  description = "Tipo de cuenta de almacenamiento del disco del sistema operativo"
  type        = string
  default     = "Standard_LRS"
}

variable "os_disk_name" {
  description = "Nombre opcional del disco del sistema operativo. Si se deja vacío, se construye a partir del proyecto y el ambiente"
  type        = string
  default     = ""
}

variable "os_image" {
  description = "Configuración de la imagen del sistema operativo"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

variable "custom_data" {
  description = "Script de bootstrap en texto plano para ejecutar al iniciar la máquina virtual"
  type        = string
  default     = <<-EOF
#!/bin/bash
apt-get update
apt-get install -y apache2
systemctl enable apache2
systemctl start apache2
EOF
}
