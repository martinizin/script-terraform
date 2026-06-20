# variables.tf
# Variables de configuración del despliegue de TechUStart.
# El PRD fija exactamente estas dos variables para mantener el contrato del ejercicio.

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
