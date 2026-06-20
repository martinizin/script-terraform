variable "azure_region" {
  description = "Azure region where resources will be deployed"
  type        = string
  default     = "eastus"
}

variable "tamano_vm" {
  description = "VM SKU size"
  type        = string
  default     = "Standard_B1s"
}

variable "project_name" {
  description = "Project name used as prefix for resource names"
  type        = string
  default     = "techustart"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod, etc.)"
  type        = string
  default     = "dev"
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    environment = "dev"
    project     = "techustart"
  }
}

variable "vnet_address_space" {
  description = "Virtual network address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefixes" {
  description = "Subnet address prefixes"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "public_ip_allocation_method" {
  description = "Public IP address allocation method"
  type        = string
  default     = "Static"
}

variable "public_ip_sku" {
  description = "Public IP SKU"
  type        = string
  default     = "Standard"
}

variable "nsg_rules" {
  description = "Network security group rules list"
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
  description = "Network interface private IP address allocation method"
  type        = string
  default     = "Dynamic"
}

variable "admin_username" {
  description = "Virtual machine administrator username"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key for administrator user authentication"
  type        = string
}

variable "os_disk_caching" {
  description = "OS disk caching type"
  type        = string
  default     = "ReadWrite"
}

variable "os_disk_storage_account_type" {
  description = "OS disk storage account type"
  type        = string
  default     = "Standard_LRS"
}

variable "os_disk_name" {
  description = "Optional OS disk name. If empty, it will be built from project and environment"
  type        = string
  default     = ""
}

variable "os_image" {
  description = "Operating system image configuration"
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
  description = "Plain text bootstrap script to run on virtual machine first boot"
  type        = string
  default     = <<-EOF
#!/bin/bash
apt-get update
apt-get install -y apache2
systemctl enable apache2
systemctl start apache2
EOF
}
