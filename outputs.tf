output "public_ip_address" {
  description = "Development virtual machine public IP address"
  value       = azurerm_public_ip.pip.ip_address
}
