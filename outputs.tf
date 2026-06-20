# outputs.tf
# Expone la información útil generada por el despliegue.

output "public_ip_address" {
  description = "Dirección IP pública de la VM de desarrollo"
  value       = azurerm_public_ip.pip.ip_address
}
